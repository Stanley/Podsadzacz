# encoding: utf-8
##
# Klasa reprezentująca zbiór przystanków o tej samej nazwie
class Hub

#  property :name, Text, :key => true, :unique => true
#  property :neighbors, Object
#  property :node, Boolean
#  property :timetables, Object
#  property :lat, Float
#  property :lng, Float
#  validates_present :name

#  def self.repository_name;:in_memory;end
#  def self.auto_migrate_down!(rep);end
#  def self.auto_migrate_up!(rep);end
#  def self.auto_upgrade!(rep);end

  attr_accessor :stops, :timetable, :timetables_by_hub

  def initialize(name, timetable_line_id = nil)

    @name = name
    # Array of Stops in Hub
    @stops = []
    # Hash of Arrays of Stops, sorted by name (hub)
    @connections = {}
    # Hash of Arrays of Timetables, sorted by next stop name (hub)
    @timetables_by_hub = {}
    next_stop = nil

    Timetable.by_hub(:startkey => [name], :endkey => [name, {}] ).each do |row|
      if(row['couchrest-type'] == "Stop")
        stop = Stop.new row
        if(stop.name == name)
          @stops << stop
        else
          next_stop = stop.name
          @connections[next_stop] ||= []
          @connections[next_stop] << stop
        end
      else
        @timetables_by_hub[next_stop] ||= []
        @timetables_by_hub[next_stop] << row
        @timetable = row if @timetable.nil? and row['line_id'] == timetable_line_id
      end
    end
  end

  def name
    @name
  end

  def timetables
    @timetables_by_hub.values.flatten
  end

  def lat
    @lat ||= stops.map{|x| x.lat}.inject{|sum, n| sum + n } / stops.size
  end

  def lng
    @lng ||= stops.map{|x| x.lng}.inject{|sum, n| sum + n } / stops.size
  end

  def neighbors
    @connections.map{|s| s.name}  # stops.inject([]){|sum, stop| sum += stop.nextstops_names}
  end

  def lat_lng
    [lat, lng]
  end

#  def angle(dst)
#    a = dst.lat - lat
#    b = dst.lng - lng
#    c = Math.sqrt(a**2 + b**2)
#
#    if(c == 0)
#      0
#    elsif(b > 0) # I lub II ćwiartka
#      (Math.acos(a/c) / Math::PI*180).round
#    else # III lub IV ćwiartka
#      ((2*Math::PI - Math.acos(a/c)) / Math::PI*180).round
#    end
#  end

#  def include?(stop)
#    stops.include?(stop)
#  end

  # Rozkłady, które docierają do hub
  def &(hub)
    (timetables.map{|t| t.nextinline.stop if t.nextinline}.compact & hub.timetables.map{|t| t.stop}).map{|s| s.timetables}.flatten
  end

  # Przystanki sąsiadujące
#  def neighbor_nodes
##    out = []
##    neighbors.each do |name|
##      out << Hub.get(name)
##    end
##    out
#    @connections
#  end

  # returns: [cost, timetable]
  def cost(stop, time)

    p "Czas: " + time.to_s
    # czas oczekiwania, czas podróży, Timetable
    next_run = 1.0/0
    run_number = nil
    timetable = nil

    # iteracja po rozkładach linii, które docierają do przystanku stop
    # wybierz najbliższy kurs
    @timetables[stop['_id']].each do |t|

      p "nextrun"
      min, run = t.nextrun(time)

      if not min.nil? and min < next_run
        next_run = min
        run_number = run
        timetable = t
      end



#      if not next_run.nil? and ( run.nil? or next_run < run[0] )
#        begin
#          arrival = timetable.arrival(new_time, run_number)
#        rescue
#          p timetable
#          raise
#        end
#
#        trip_time = (arrival - new_time).to_i
#  #          czas oczekiwania, czas podróży, Timetable
#        run = [next_run, trip_time / 60 - next_run, x]
#        break if next_run == 0
#      end
    end


    arrival = timetable.nextinline.arrival(time + next_run * 60, run_number)
    trip_time = (arrival - time).to_i / 60

    stretch = Stretch.new( timetable, next_run, trip_time )

    [heuristic_distance(stop), stretch]
  end

  # distance in straight line from self to goal in km
  def heuristic_distance(goal)
    r = 6371
    to_rad = 3.142 / 180
    d_lat = (goal.lat - lat) * to_rad
    d_lng = (goal.lng - lng) * to_rad
    a = Math.sin(d_lat / 2) * Math.sin(d_lat / 2) +
        Math.cos(lat * to_rad) * Math.cos(goal.lat * to_rad) *
        Math.sin(d_lng / 2) * Math.sin(d_lng / 2)
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    r * c
  end

  def time_to(hub, time = Time.now)
    sum = 0
    res = SearchQuery.new(:from => name, :to => hub.name, :time => time)
    result = res.result
#    res.result.each do |route|
    return nil if result.empty?

    sum += result.map{|x| x[0] + x[1]}.inject(0){|sum,x| sum+x}
#    end
#    p res if sum == 0
    sum
  end

  def time_to_all(time = Time.parse("12:00"))
    out={lat_lng => 0}
    @@hubs ||= Stop.all.map{|x| x.name}.uniq.map{|x| Hub.get(x)}
    (@@hubs - [self]).each do |hub|
      duration = time_to(hub, time)

      if not duration.nil?
        out[hub.lat_lng] = duration
#        print "."
#      else
#        print "x"
      end
    end
    out
  end
end
