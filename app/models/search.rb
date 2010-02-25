# encoding: utf-8
##
# Reprezentuje zapytanie wklepane przez użytkownika
# Posiada metody do wyszukiwania połączeń pomiędzy przystankami
class Search < CouchRestRails::Document
  use_database :searches

  property :from        #, String
  property :to          #, String
  property :time,       :cast_as => "Time"
  property :user_ip     #, String
  property :user_agent  #, String
  property :created_at, :default => Time.now

  private

#  def start
#    @start ||= Hub.get(from)
#  end
#
#  def goal
#    @goal ||= Hub.get(to)
#  end
#
#  def finish
#    @finish ||= finish_timetables.map{|x| x.stop.opposite}.flatten.uniq
#  end

  ##
  # Kąt pomiędzy początkowymi i końcowymi przystankami
#  def direction
#    @direction ||= Hub.first_or_create(:name => from_names.join(",")).angle(Hub.first_or_create(:name => to_names.join(",")))
#  end

#  def start_timetables
#    Hub.first_or_create(:name => from).timetables
#  end
#
#  def finish_timetables
#    Hub.first_or_create(:name => to).timetables
#  end

  public

  def dev

    @start_hub  = Hub.new from
    @finish_hub = Hub.new to

    path = find_path2

#    p "RESULT: " + path.map{|timetable| timetable.stop.name}.join(", ")
    path.each do |s|
      p "Przystanek: " + s.node + " ( " + s.timetable['line'].to_s + " ), czas oczekiwania: " + s.wait.to_s + ", czas podróży: " + s.ride.to_s
    end

    path
  end

  ##
  # Metoda ta służy do znajdywania tras, które łączą przystaki początkowe i końcowe.
  # Input: Brak, wymagane jest zadeklarowanie wartości 'from' i 'to' obiektu.
  # Output: ...
  # Output format: ...
  # Best-first graph search algorithm that finds the least-cost path from a given initial node to one goal node (out of one or more possible goals).
  def find_path2
    raise 'Brak danych' unless from and to

    been_there = []

    # Kolejka piorytetowa która przechowuje inforacje o: nazwie i heurystyce przystanku, najkorzystniejszym kursie rozkładu jazdy
    queue = PriorityQueue.new
    queue << [1, [@start_hub, [], 0, 0]]

    while not queue.empty?
        # name: String, path: Array of [czas oczekiwania, czas podróży, Timetable], cost: Int

      # Pobierz z kolejki priorytetowej najbliższy wariant
      hub, path_so_far, cost_so_far, time_so_far = queue.next
      current_time = time + time_so_far

      hub.timetables_by_hub.each_pair do |node, timetables|
        
        next if been_there.include?(node) or node.nil?
        been_there.push(node)

        # wybierz pierwszy rozkład zmierzający do hub
        timetable = nil
        run_number = nil
        wait = 30 # don't wait longer than 30 minute
        timetables.each do |t|
          next_run, run = t.nextrun(current_time)
          if (next_run and next_run < wait)
            wait = next_run
            run_number = run
            timetable = t
            break if wait == 0
          end
        end

        # Obsłuż brak połączeń
        next unless timetable

        next_hub = Hub.new node, timetable.line_id
        timetable.nextinline = next_hub.timetable

        # oblicz czas podróży
        departure = current_time + wait * 60
        arrival = timetable.nextinline ? timetable.nextinline.arrival(departure, run_number) : departure + 2*60 
        trip_time = (arrival - departure).to_i / 60

        stretch = Stretch.new( timetable, node, wait, trip_time )
        new_path = path_so_far + [stretch]
        return new_path if node == to

        # dodaj rozkład do kolejki
        new_cost = hub.heuristic_distance(next_hub) + cost_so_far
        queue << [new_cost + @finish_hub.heuristic_distance(next_hub), [ next_hub, new_path, new_cost, time_so_far + (wait + trip_time)*60]]
      end
    end
    return []
  end

  def result




#    def nextinline(x, timetables, hub_name)
#      timetables.each do |z|
#        if z.line_id == x.line_id and z.nice > x.nice
#          return z
#        end
#      end
#
##      p "Następny dla " + x.stop.name + " jest " + x.nextinline.stop.name
#      z = x.nextinline
#      z.stop.name == hub_name ? z : nil
#    end

#    raise 'Podaj czas' unless time
#    return [] if Hub.get(from).timetables.empty? or Hub.get(to).timetables.empty?

    path = find_path
    return [] if path.empty?

    out = []
    new_time = time
    prev_timetables = path.shift.timetables
    path.each do |hub|
       timetables = []
       current_timetables = hub.timetables.dup
       prev_timetables.each do |x|
         y = nextinline(x, current_timetables, hub.name)
         current_timetables.delete(y)
         timetables << [x, y] if not y.nil? and y.level == 0
       end

      run = nil # możliwy / przewidywalny
      timetables.each do |x, y|
        next_run, run_number = x.nextrun(new_time)
        if not next_run.nil? and ( run.nil? or next_run < run[0] )
          begin
            arrival = y.arrival(new_time, run_number)
          rescue
            p y
            raise
          end

          trip_time = (arrival - new_time).to_i
#          czas oczekiwania, czas podróży, Timetable
          run = [next_run, trip_time / 60 - next_run, x]
          break if next_run == 0
        end
      end
      return [] if run.nil?
      new_time += (run[0] + run[1])*60
      out << run
      prev_timetables = hub.timetables
    end
    out
  end

  ##
  # Metoda ta służy do znajdywania tras, które łączą przystaki początkowe i końcowe.
  # Input: Brak, wymagane jest zadeklarowanie wartości 'from' i 'to' obiektu.
  # Output: ...
  # Output format: ...
  # Best-first graph search algorithm that finds the least-cost path from a given initial node to one goal node (out of one or more possible goals).
#  def find_path
#    raise 'Brak danych' unless from and to
#
#    been_there = {}
#
#    # Kolejka piorytetowa która przechowuje inforacje o: nazwie i heurystyce przystanku, najkorzystniejszym kursie rozkładu jazdy
#    queue = PriorityQueue.new
#    queue << [1, [from, [], 0, 0]]
#
#
#    while not queue.empty?
##      begin
#        # name: String, path: Array of [czas oczekiwania, czas podróży, Timetable], cost: Int
#        spot, path_so_far, cost_so_far, time_so_far = queue.next
#        return path_so_far if (spot == to)
#        hub = Hub.new spot
#        next if been_there[spot]
#        been_there[spot] = true
#        p "- " + hub.name
#        hub.neighbor_nodes.each do |stop|
#          next if been_there[stop.name]
#          new_cost, stretch = hub.cost(stop, time + time_so_far)
#          new_cost += cost_so_far
#          queue << [new_cost + @finish_hub.heuristic_distance(stop), [stop.name, path_so_far + [stretch], new_cost, time_so_far + stretch.duration]]
#        end
##      rescue
##        raise "Wystąpił błąd przy: " + self.inspect
##      end
#    end
#    return []
#  end

end
