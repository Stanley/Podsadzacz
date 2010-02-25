# encoding: utf-8
##
# Obiekt reprezentuje linię komunikacji miejskiej.
class Line < CouchRestRails::Document
  use_database :podsadzacz

#  has n, :timetables #, :dependent => :destroy
#  has n, :stops, :through => :timetables

  property :id
  property :no          # Integer,  :nullable => false, :message => "Musisz podać numer linii"
  property :direction   # String
  property :begin_date, :cast_as => 'Date', :init_method => :parse  # :nullable => false, :message => "Należy podać początek daty ważności linii"
  property :end_date,   :cast_as => 'Date', :init_method => :parse  # :nullable => true
  property :length      # Float,    :default => 0
  property :temporary   # Boolean,  :default => false

  timestamps!

  view_by :no,
    :map =>
      "function(doc){
        if (doc['couchrest-type'] == 'Line'){
          emit([doc.no, doc['_id']], doc)
        } else if (doc['couchrest-type'] == 'Timetable' && doc.nice == 0){
          emit([doc.line, doc.line_id, 0], {'_id': doc.stop_id})
        }
      }"

  view_by :dest,
    :map =>
      "function(doc){
        if (doc['couchrest-type'] == 'Line'){
          emit([doc.no, doc.destination, doc['_id']], null)
        }
      }",

    :reduce =>
      "function(keys, values, rereduce){
        if(!rereduce){
          var stops = {}
          keys.forEach(function(key){
            stops[key[1]] = key[0][1]
	        })
          return( stops )
        }
      }"
  
  view_by :id,
    :map =>
      "function(doc){
        if (doc['couchrest-type'] == 'Line'){
          emit(doc.id, doc)
        }
      }"

  view_by :stop,
    :map =>
      "function(doc){
        if (doc['couchrest-type'] == 'Stop'){
          emit([doc['_id']], doc)
        }
        if (doc['couchrest-type'] == 'Timetable'){
          emit([doc.stop_id, 0], {'_id': doc.line_id})
        }
      }"

  def check_line_no_count
    if Line.count(:no => no) > 1
      [false, "Unable to create 3-rd active line number " + no.to_s]
    else
      true
    end
  end

  public

  def stops
    @stops ||= Stop.by_line :startkey => [self['_id'], nil], :endkey => [self['_id'], {}]
  end

  def timetables
    @timetables ||= Timetable.by_line :startkey => [self['_id'], 0], :endkey => [self['_id'], {}]
  end

  # Czy to jest konieczne?
  def runs?(date)
    not timetables.all?{|x| x.minutes(date).blank?}
  end

  ##
  # Output: wszystkie linie tramwajowe
  def self.trams
    all :no.gt => 0, :no.lt => 100
  end

  ##
  # Output: wszystkie linie autobusowe
  def self.buses
    all :no.gt => 99, :no.lt => 1000
  end

  ##
  # Tworzy linie o zadanym numerze
  # Input: numer linii, tablicę przystanków
  # Format tablicy przystanków:
  # [         - tablica linii
  #   [       - tablica odcinków linii (gdy linia składa się z wielu odcinków)
  #     [     - tablica fizycznych przystanków dla jednego przystanku, nazwy (do wyboru)
  #       Stop
  # ...

  def self.auto_create(no, stops, date)
    out = []
    transaction do |txn|
      Mpk.each_line no, stops, date do |line|
        alternate_timetables = line[1].sort_by{|x| x.length }.reverse
        primary = Line.create!( line[0] ) #.merge({:begin_date => Date.parse("2009-08-28")}))
        primary_timetables = alternate_timetables.shift
        min = primary_timetables.map{|t| t[:nice]}.min.to_i
        primary_timetables.each do |t|
          primary.timetables.build(t.merge({:nice => t[:nice].to_i - min}))
        end
        unless alternate_timetables.empty?
          alternate_timetables.map! do |timetables|
            timetables.map{|t| Timetable.new(t)}.sort_by{|t| t.nice}
          end
          alternate_timetables.sort_by{|x| x[0].first(primary.begin_date)}.each do |timetables|
            #p "odcinek " << timetables.first.stop.name << " - " << timetables.last.stop.name

            if timetables.last.runs(primary.begin_date) + primary.timetables.sort_by{|x| x.nice}[0].runs(primary.begin_date) == primary.timetables.sort_by{|x| x.nice}[1].runs(primary.begin_date)
              #p " jest początkiem (wariant Y)"
              primary.timetables.each do |t|
                t.nice += timetables.size
              end
              timetables.each_with_index do |t,i|
                t.nice = i
                t.level = 1
                attr = t.attributes
                attr.delete(:line_id)
                primary.timetables.build( attr )
              end
              break
            elsif timetables[-1].last(primary.begin_date) > primary.timetables.sort_by{|x| x.nice}[-1].last(primary.begin_date)
              #p " jest końcem"
              timetables.each_with_index do |t,i|
                t.nice = primary_timetables.size + i
                t.level = 1                
                attr = t.attributes
                attr.delete(:line_id)
                primary.timetables.build( attr )
              end
              break
            elsif timetables.size == 1 and t = timetables.last and t2 = primary.timetables.select{|x| x.stop.name == t.stop.name}[0] and t.runs(primary.begin_date) + t2.runs(primary.begin_date) == primary.timetables.select{|x| x.nice == t2.nice + 1}[0].runs(primary.begin_date)
              #p " jest alternatywnym początkiem"

              primary.timetables.select{|x| x.nice > t2.nice}.each do |x|
                x.nice += 1
              end

              t.nice = t2.nice + 1
              t.level = 1
              attr = t.attributes
              attr.delete(:line_id)
              primary.timetables.build( attr )            
            end

            index = 0
            first_first = timetables.first.first(primary.begin_date)
            last_first = timetables.last.first(primary.begin_date)
            last_last = timetables.last.last(primary.begin_date)
            while(timetable = primary.timetables.sort_by{|t| t.nice}[index])
              begin
                nextinline = primary.timetables.sort_by{|t| t.nice}[index+1]
                nextrun = nextinline.nextruns(last_first, 1)[0]
                raise ArgumentError if nextrun == 0
                run_number = nextinline.run_number( last_first + nextrun * 60 )
                timetable.arrival( primary.begin_date, run_number )
                timetable.last( primary.begin_date )
                if( first_first > timetable.arrival( primary.begin_date, run_number )) and last_last < nextinline.last( primary.begin_date )
                  #p " idzie po: " << timetable.stop.name
                  primary.timetables.map!{|t| t.nice <= timetable.nice ? t : t.nice += timetables.size; t}
                  timetables.each_with_index do |t, i|
                    t.nice = timetable.nice + i + 1
                    t.level = timetable.level + 1
                    attr = t.attributes
                    attr.delete(:line_id)
                    primary.timetables.build( attr )
                  end
                  break
                end
              rescue
              end
              index += 1
            end
          end
        end
        primary.normalize
        out << primary
      end
    end
    out
  end

  ##
  # - Uzupełnianie rozkładu o wartości nil : kursy z przystanku inny niż pierwszy
  # - Uzupełnianie rozkładu o wartości nil : kursy oznaczone A-Z
  # Bierze pod uwagę rozkłady z tablicy @_timetables
  # Output: nil lub błąd
  def normalize

    previnline = nil

    @timetables = []
    timetables.sort_by{|t| t.nice}.each do |t|
      @timetables.unshift(t)
    end

    # Część I :: Uzupełnianie rozkładu o wartości nil : kursy z przystanku inny niż pierwszy
    #@timetables.map! do |timetable|
    #  if nextinline
    #    timetable.each do |minutes, day|
    #      nextinline.minutes_by_table_no(day).each_with_index do |minute, i|
    #        #or minute.nil?
    #        if (nextinline.minutes_by_table_no(day).size > timetable.minutes_by_table_no(day).size and nextinline.minutes_sum_by_table_no(day, i) <= timetable.minutes_sum_by_table_no(day, i))
    #          timetable.minutes_by_table_no(day).insert(i, nil)
    #        end
    #      end
    #      (nextinline.minutes_by_table_no(day).size - timetable.minutes_by_table_no(day).size).times do
    #        timetable.minutes_by_table_no(day).push(nil)
    #      end
    #    end
    #  end
    #  nextinline = timetable
    #end
    
    (0..2).each do |day|
      nextinline = nil
      @timetables.map! do |timetable|
        minutes = timetable.minutes_by_table_no(day)
        if nextinline and minutes.size > 0
          next_minutes = nextinline.minutes_by_table_no(day)
          next_minutes.each_with_index do |minute, i|
            #or minute.nil?
            if timetable.stop.name == nextinline.stop.name and next_minutes.size != minutes.size
              minutes.insert(i, nil) unless minute.nil?
            elsif next_minutes.size > minutes.size and nextinline.minutes_sum_by_table_no(day, i) <= timetable.minutes_sum_by_table_no(day, i)
              minutes.insert(i, nil)
            end
          end
          (next_minutes.size - minutes.size).times do
            minutes.push(nil)
          end
        end
        nextinline = timetable if minutes.size > 0
        timetable
      end
    end

    # Część II :: Uzupełnianie rozkładu o wartości nil : kursy oznaczone A-Z
    indexes = {}
    @timetables.reverse.each do |timetable|
      timetable.each do |minutes, day|
        indexes[day] ||= []
        if previnline
          previnline.minutes_by_table_no(day).reverse.each_with_index do |minute, i|
            i = -i-1
            if indexes[day].include?(i) or (not minute.nil? and not timetable.minutes_by_table_no(day)[i].nil? and previnline.minutes_by_table_no(day).size > timetable.minutes_by_table_no(day).size and (previnline.minutes_sum_by_table_no(day, i) >= timetable.minutes_sum_by_table_no(day, i)))
              timetable.minutes_by_table_no(day).insert(i, nil) # rescue timetable.minutes_by_table_no(day).unshift(nil)
              indexes[day] << i unless indexes[day].include? i
            end
          end

          (previnline.minutes_by_table_no(day).size - timetable.minutes_by_table_no(day).size).times do
            timetable.minutes_by_table_no(day).unshift(nil)
          end
        end        
      end
      previnline = timetable
      timetable.save!
    end
  end

  #def self.auto_create(line_no, all_lines, date)
  #  lines = []
  #  transaction do |txn|
  #    Mpk.each_line line_no, all_lines, date do |line_partials|
  #      primary = nil
  #      line_partials.sort_by{|x,y| y.size}.reverse.each do |arr|
  #        line_hash, timetable_hashes = arr
  #        line = Line.new(line_hash)
  #        timetable_hashes.sort_by{|t| t[:nice].to_i}.each_with_index do |t,i|
  #          timetable = line.timetables.build(t)
  #          if primary.nil?
  #            timetable.nice = i
  #          end
  #        end
  #        if not primary.nil?
  #          line.primary_line_id = primary.id
  #          line.primary_line = primary
  #        end
  #        line.save!
  #        if primary.nil?
  #          lines << (primary = line)
  #        else
  #          line.slave
  #        end
  #      end
  #      primary.normalize
  #    end
  #  end
  #  lines
  #end

  ##
  # Input: numer linii oraz nazwa pierwszego przystanku na linii
  def self.latest_archived(no, begin_stop_name)
    Line.repository(:archive) do
      Line.all(:no => no).select{ |x| (x.timetables.first.stop.name.casecmp(begin_stop_name) === 0) rescue false }.sort_by{|x| x.begin_date}.last
    end
  end



  ##
  # Output: [Array]
  # Tablica z rozkładami przystanków na całej linii
  # Jeżeli rozkład należy do primary line, w tablicy reprezentuje go obiekt Timetable
  # Jeżeli rozkład należy do slave line, jest on umieszczany w (odpowiedniej dla linii) tablicy

  #def all_timetables
  #
  #  return primary_line.all_timetables unless primary_line_id == nil
  #
  #  all = (slave_lines.map{|x| x.timetables} + timetables).flatten.sort_by{|x| x.nice}
  #  out = []
  #  cache = []
  #
  #  all.each do |t|
  #    if id != t.line_id
  #      cache << t
  #    else
  #      unless cache.empty?
  #        out << cache
  #        cache = []
  #      end
  #      out << t
  #    end
  #  end
  #  out << cache unless cache.empty?
  #  out
  #end

  # Proces uniwalania linii: Sortowanie przystanków danej linii oraz zmiana piorytetów primary line
  #def slave
  #  raise RuntimeError unless primary_line_id
  #
  #  timetables.each do |t|
  #    t.line_id = id
  #  end
  #
  #  primary_timetables = primary_line.timetables
  #  first_time = timetables.first.first(begin_date)
  #  last_time = timetables.last.first(begin_date)
  #  last_run = timetables.last.last(begin_date)
  #  index = 0
  #
  #  while(timetable = primary_timetables[index])
  #
  #    # Spawdź czy przyjazd kursu () na dany przystanek następuje przed przyjazdem na potencjalny następny przystanek
  #    if nextinline = primary_timetables[index+1] and nextrun = nextinline.nextruns(last_time, 1)[0] and nextrun > 0 and run_number = nextinline.run_number( last_time + nextrun * 60) and (first_time > timetable.arrival( begin_date, run_number) rescue false) and last_run < timetable.last(begin_date) # and (last_time < ( last_time + nextrun * 60) - timetable.arrival( begin_date, run_number))
  #      #p "segment " << timetables.first.stop.name << " - ... idzie po: " << timetable.stop.name
  #      #p "first_time: #{first_time.to_s} > timetable.arrival( begin_date, run_number): timetable.arrival( #{begin_date.to_s}, #{run_number.to_s}) = #{timetable.arrival( begin_date, run_number)}"
  #
  #      timetables.each_with_index do |t,i|
  #        t.nice = timetable.nice + i + 1
  #      end
  #
  #      while( nextinline = primary_timetables[index + 1] )
  #        nextinline.nice += timetables.size
  #        index += 1
  #      end
  #      return nil
  #    end
  #    index += 1
  #  end
  #
  #  #p "odcinek " << @_timetables.first.stop.name << " - " << @_timetables.last.stop.name
  #
  #  if timetables.last.runs(begin_date) + primary_timetables[0].runs(begin_date) == primary_timetables[1].runs(begin_date)
  #    #p " jest początkiem (wariant Y)"
  #    timetables.each_with_index do |t,i|
  #      t.nice = i
  #      #t.save
  #    end
  #    primary_timetables.each_with_index do |t,i|
  #      t.nice = timetables.size + i
  #    end
  #  else
  #    #p " jest końcem"
  #    timetables.each_with_index do |t,i|
  #      t.nice = primary_timetables.size + i
  #      #t.save
  #    end
  #  end
  #
  #  primary_timetables.each do |t|
  #    t.save
  #  end
  #
  #  timetables.each do |t|
  #    t.save
  #  end
  #end

  #def sort_alternates
  #  alternates = timetables.select{|x| x.level > 0}.sort_by{|x| x.first(begin_date)}.reverse
  #  primary = timetables - alternates
  #
  #  # wybierz pierwszy (czasowo) rozkład z kolejki alternatywnych
  #  while(altern = alternates.pop)
  #    index = 0
  #    while(timetable = primary[index])
  #      if nextinline = primary[index+1] and nextrun = nextinline.nextruns(last_time, 1)[0] and nextrun > 0 and run_number = nextinline.run_number( last_time + nextrun * 60) and (first_time > timetable.arrival( begin_date, run_number) rescue false) and last_run < timetable.last(begin_date) # and (last_time < ( last_time + nextrun * 60) - timetable.arrival( begin_date, run_number))
  #      end
  #    end
  #  end
  #
  #
  #
  #    # Spawdź czy przyjazd kursu () na dany przystanek następuje przed przyjazdem na potencjalny następny przystanek
  #
  #      #p "segment " << timetables.first.stop.name << " - ... idzie po: " << timetable.stop.name
  #      #p "first_time: #{first_time.to_s} > timetable.arrival( begin_date, run_number): timetable.arrival( #{begin_date.to_s}, #{run_number.to_s}) = #{timetable.arrival( begin_date, run_number)}"
  #
  #      timetables.each_with_index do |t,i|
  #        t.nice = timetable.nice + i + 1
  #      end
  #
  #      while( nextinline = primary_timetables[index + 1] )
  #        nextinline.nice += timetables.size
  #        index += 1
  #      end
  #      return nil
  #    end
  #    index += 1
  #  end
  #end

  ##
  # Sprawdza które linie się zdeaktualizowały i archiwuje je do repozytorium :archive
  # TODO: i podmienia obiekt z pamięci na nowy
  def archive
    raise "Nie można archiwizować nezapisanej linii" if new_record?

    archived = nil
    transaction do |txn|
      Line.repository(:archive) do
        new_attr = attributes
        new_attr.delete(:id)
        archived = Line.create! new_attr
        timetables.each do |t|
          new_t_attributes = t.attributes
          new_t_attributes.delete(:id)
          new_t_attributes[:line_id] = archived.id
          Timetable.create! new_t_attributes
        end
      end
      raise "Nie mogę usunąć linii" unless destroy
    end
    archived
  end

  def polylines
    @polylines ||= Polyline.by_line( :startkey => [self['_id'], nil], :endkey => [self['_id'], {}] ).map{|p| p.points}
#    ids = timetables.map{|x| x.stop_id if x.level == 0}.compact
#    ids << direction.id if direction
#    all = Polyline.all(:beg_id => ids, :end_id => ids)
#    all.each{|p| p.line = id}
  end

  ##
  # Output<Line>: Linia przeciwna
  def opposite
    @opposite ||= Line.by_dest(:startkey => [no]).select{|x| x['_id'] != self['_id']}.first
  end

  ##
  # Przystanek docelowy
  # Zwraca przystanek <Stop>, który jest pierwszy na linii przeciwnej lub, jeżeli istnieje, przeciwny do niego
  # Zwraca ostatni przystanek danej linii jeżeli brak przeciwnej
  # Zwraca błąd gdy brak rozkładów
#  def direction
#    opposite.stops.first
##    raise "Brak rozkładów" if timetables.empty?
##    Merb::Cache[:memcached].fetch("Line:" + id.to_s + ":direction") {
##    @direction ||= Stop.get(
##      if (opposite_line_first_stop = opposite.timetables.select{|x| x.level == 0}.first.stop rescue false)
##        if not (stops = opposite_line_first_stop.opposite.select{|x| x.prevstops.include?(timetables.last.stop)}).empty?
##          stops.first.id
##        else
##          opposite_line_first_stop.id
##        end
##      else
##        timetables.last.stop_id
##      end
##    )
#  end

  def direction
    Stop.get self['direction']
  end

  ##
  # Zwraca nazwę direction
  # Zwraca "Nieznany" gdy brak direction
#  def direction_name
#    direction ? direction.name : (opposite.timetables.first.stop.name rescue "Nieznany")
#  end

  ##
  # Output: <Stop> Drugi przystanek końcowy 
  def alternate_direction
    return nil if timetables.last.level != 1
    opposite.timetables.first.stop
  end

  ##
  # Output: Liczba kursów linii [min, max]
  # Input<Date>
  def runs(date)
    timetables.blank? ? 0 : timetables.map{|x| x.runs(date)}.max
  end

  ##
  # Output<Integer>: czas potrzeby do przejechania od pętli do pętli danego kursu w minutach
  # Input: numer kursu z zakresu 0..runs-1, data
  # TODO: dodaj czas przejazdu ostatniego przystanku
  def time(date, kurs = 0)

    return 0 unless runs?(date)
#     raise "Zły argument: kurs" if runs(date) < kurs

    temp = timetables.select{|t| t.level == 0}
    (temp.last.arrival(date, kurs) - temp.first.arrival(date, kurs)).to_i / 60
  end

  # Output<Array>: Ciąg minut, które są potrzebne do przejechania całej trasy n-tym kursem. Patrz #time.
  def times(date)

    if @times
      @times
    else
      @times = []
      runs(date).times do |i|
        (@times << time(date, i)) rescue nil
      end
      @times
    end
  end

  ##
  # Output<Integer>: Średni czas przejazdu od początku do końca podany w minutach jako Float
  def avg_time(date)
    t = times(date)
    t.inject{|x,y| x + y} / t.size #timetables.map{|x| x.avg_speed(date)}.inject{|x,y| x + y}.to_i
  end

  ##
  # Output<Array>: Czas najszybszego i najwolniejszego przejazu
  # UWAGA: wolne?
  # TODO: ZAMIAST CO 3 USTAL UŁAMEK np. 1/5
  def thefastest_theslowest(date)
    
    return [0,0] unless runs?(date)
#     Merb::Cache[:memcached].fetch "Line:" + id.to_s + ":thefastest_theslowest" do
      all = times(date)
      #0.step(runs(date).last, 3) do |i|
#      10.times do |i|
#        j = (runs(date) / 20) * i
#        (times << time(date, j)) rescue nil # ekhem...
#      end


      all.compact!
      raise "Zbyt mało danych" if all.size < 2
      [all.min, all.max]
#     end
  end

  ##
  # Output<Integer>: Procent określający podatność na korki
  def rush_percent(date)
    return 0 if (arr = thefastest_theslowest(date))[1] == 0
    (100 - (arr[0] / arr[1].to_f) * 100).round
  end

  ##
  # Output<Integer>: Średni okres kursowania w minutach
  def okres(date)
    return 0 unless runs?(date)
    timetables.first.minutes_sum(date) / timetables.first.runs(date)
  end

  def period
    (begin_date..(end_date || Date.today))
  end

  ##
  # Output<Bool>: Linia tramwajowa?
  def tram?
    (0..99).include?(no)
  end

  ##
  # Output<Bool>: Linia autobusowa?
  def bus?
    (100..999).include?(no)
  end

  ##
  # Output<Bool>: Normalna, przyspieszona lub wspomagająca linia autobusowa?
  def normalBus?
    (100..299).include?(no) or (400..499).include?(no)
  end

  ##
  # Output<Bool>: Przyspieszona linia autobusowa?
  # 200..299 - zwykłe przyspieszone
  # 300..399 - aglomeracyjne przyspieszone
  def fastBus?
    (200..399).include?(no)
  end

  ##
  # Output<Bool>: Strefowa linia autobusowa (również przyspieszona)?
  def zonalBus?
    (300..399).include?(no) or (500..599).include?(no)
  end

  ##
  # Output<Bool>: Nocna linia autobusowa?
  def nightBus?
    (600..699).include?(no) or (900..999).include?(no)
  end

  ##
  # Output<String>: Trasa lini jako nazwy ulic
  def route
#    timetables.map{|x| x.stop.location if x.level == 0}.uniq.select{|x| not x.blank?}.join(", ")
    stops.map{|x| x.location}.uniq.select{|x| not x.blank?}.join(", ")
  end

  def active?
    true
  end

  ##
  # Zwraca hash z opisem kursów i ich względnymi indeksami
  # Example: {"A - Kurs do przystanku Bronowice" => [50, 55, 56]}
  # Example2: {"B - Kurs przez Ruczaję" => [30, 31]}
  def description(i)
    return {}
    out = {}
    stack = []
    level = 0
    temp = timetables
    while(temp[0].level == 1)
      temp.shift
    end

    temp.reverse.each do |timetable|
      if timetable.level > level
        runs = []
        timetable.minutes_by_table_no(i).each_with_index do |min, j|
          runs << j unless min.nil?
        end
        stack.push([timetable.stop, runs])
        level = timetable.level
      elsif timetable.level == level
        # TODO: sprawdzaj odległości i zmień opis trasy ???
      else
        stop, runs = stack.pop
        out.each_value do |val|
          runs -= val
        end
        out[["Kurs przez " + stop.name, timetable.nice]] = runs
        level = timetable.level
      end
    end

    short = [] # kursy do oznaczenia (nie dojeżdzają do pętli)
    temp = timetables.select{|t| t.level == 0}
    temp.pop.minutes_by_table_no(i).each_with_index do |m, j|
      short << j if m.nil?
    end

    short.each do |j|
      temp.each do |t|
        if t.minutes_by_table_no(i)[j].nil?
          key = ["Kurs do przystanku " + t.stop.name]
          out[key] ||= []
          out[key] << j
          break
        end
      end
    end
    out
  end

  def temp?
    false
  end

  def length
    self['length'] || 0
  end

  ##
  # Output: Hash of urls to all mantained charts
  def gchart(date)
#     Merb::Cache[:memcached].fetch "Line:" + id.to_s + ":gcharts" do
    return @gchart unless @gchart.blank?
    return {} if timetables.empty?

    @gchart = {}

#    require 'google_chart'
#
#    GoogleChart::BarChart.new('800x200', "Okresy kursów linii " + no.to_s + " (w minutach)", :vertical, true) do |b|
#
#      start = Time.parse(timetables.first.start.to_s + ":00")
#      data = timetables.first.minutes(date).compact
#      return {} if data.empty?
#
#      min = data[1..-1].min
#      max = data[1..-1].max
#
#      b.data "Czas", data[1..-1]
#      b.show_legend = false
#      b.axis :y, :labels => [0, min, max], :positions => [0, min, max], :range => [0, max]
#      b.axis :x, :labels => (0..data.size).to_a.map{|i| i%10 == 9 ? i+1 : ""}
#      b.axis :top, :labels => data.map!{|i| (start += i*60).strftime("%H:%M")}[1..-1].map{|x| data.index(x)%10 != 5 ? "" : x}
#      @gchart[:okres] = b.to_url(:chbh=>"a")
#    end
#
#    GoogleChart::BarChart.new('800x200', "Czas przejazdu linii " + no.to_s + " (w minutach)", :vertical, false) do |b|
#      all=times(date)
#
#      b.data "Czas", all #.map{|x| x  - all.max*(2.0/3)}
#      b.show_legend = false
#      b.axis :y, :range => [0, all.max], :labels => [all.min.to_i, all.max.to_i], :positions => [all.min, all.max]
#      b.axis :x, :labels => (0..all.size).to_a.map{|i| i%10 == 9 ? i+1 : ""}
#      b.axis :top, :labels => (0..all.size).to_a.map{|i| i%10 == 4 ? timetables.first.absolute_arrival(date, i).strftime("%H:%M") : ""}
#      b.axis :right, :range => [0, all.max], :labels => ["min", "max"], :positions => [all.min, all.max]
#      @gchart[:time] = b.to_url(:chbh=>"a")
#    end
#
#    @gchart

#       GoogleChart::ScatterChart.new('800x325', "Prędkość średnia na linii " + no.to_s) do |b|
#
#         b.axis :x, :labels => timetables.map{|x| x.stop.name[0..2]}.unshift("")
#         b.axis :y, :labels => (timetables.first.start..22).to_a.select{|x| x%2 == 0}.map{|x| x.to_s + ":00"}.unshift("")
#
#         data = []
#         sizes = []
#         timetables.each_with_index do |t,i|
#           break unless len = t.polyline.length
#           break unless t.nextinline
#           10.times do |j|
#             data << [i+1,j+1]
#             time = Time.parse(date.to_s + " " + (22 - 2*j).to_s + ":00")
#             beg_t = t.nextruns(time)
#             end_t = t.nextinline.nextruns(time)
#
#             sub = []
#             end_t.reverse.each do |x|
#               break unless c = beg_t.pop
#               if not x - c < 1
#                 sub << x - c
#               else
#                 retry
#               end
#             end
#
#             sizes << (sub.size > 0 ? len / (sub.inject{|sum,x| sum+x} / sub.size) : 0)
#           end
#         end
#
#         b.data "", data
#         b.point_sizes sizes
#         out[:avg] = b.to_url(:chbh=>"a")
#       end
#     end
  end
end
