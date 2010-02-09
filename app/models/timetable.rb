# encoding: utf-8
##
# Klasa reprezentuje rozkład jazdy danej linii na danym przystanku
class Timetable < CouchRestRails::Document
  use_database :podsadzacz

#  belongs_to :stop
#  belongs_to :line

#  property :id
  property :nice    #,    Integer
  property :stop_id #,    Integer
  property :stop_name #,  String
  property :line_id #,    Integer
  property :start   #,    Integer
  property :level   #,    Integer, :default => 0
  property :time,   :default => {}   #,    Object,  :lazy => [:table1]
#  property :table2  #,    Object,  :lazy => [:table2]
#  property :table3  #,    Object,  :lazy => [:table3]
  property :ratio   #,    Float                         # Prędkość km/h (tylko gdy istnieje polyline)

  timestamps!

  view_by :line_stop,
    :map =>
      "function(doc) {
        if (doc['couchrest-type'] == 'Timetable') {
          emit([doc.line_id, doc.stop_id], null);
        }
      }"

  # map: all timetables on the stop
  # reduce: number of lines on the stop
  view_by :stop,
    :map =>
      "function(doc){
        if (doc['couchrest-type'] == 'Timetable'){
          emit([doc.stop_id, doc.line_id], doc)
        } else if (doc['couchrest-type'] == 'Stop'){
          emit([doc['_id']], doc)
        }
      }"

  view_by :hub,
    :map =>
      "function(doc){
        if (doc['couchrest-type'] == 'Timetable'){
          emit([doc.hub, doc.stop_id, doc.next, 0], doc)
        } else if (doc['couchrest-type'] == 'Stop'){
          emit([doc.name, doc['_id']], doc)

          doc.next.forEach(function(id){
            emit([doc.name, doc['_id'], id], {'_id': id})
          })
        }
      }"

  # map: all timetables on the line
  # reduce: number of stops on the line
  view_by :line,
    :map =>
      "function(doc){
        if (doc['couchrest-type'] == 'Timetable'){
          emit([doc.line_id, doc.nice], doc)
        } else if (doc['couchrest-type'] == 'Line'){
          emit([doc['_id']], doc)
        }
      }",
    :reduce =>
      "function (key, values, rereduce) {
        if(!rereduce){
          return values.length
        } else{
          return sum(values)
        }
      }"

  view_by :time,
    :map =>
      "function(doc) {
        if(doc['couchrest-type'] == 'Timetable'){
          var i = 0
          doc.time.forEach(function(arr){
            var sum = doc.start * 60
            arr.forEach(function(min){
              sum += min
              var hour = Math.floor(sum / 60)
              if(hour < 10) hour = '0' + hour
              var minutes = sum % 60
              if(minutes < 10) minutes = '0' + minutes
              var time = hour + ':' + minutes
              emit([doc.stop_id, i, time], doc.line_id)
            })
            i += 1
          })
        }
      }"

#  property :updated_at, DateTime,:lazy => [:date]

#  validates_present :stop_id, :line_id, :message => "Musisz podać identyfikator przystanku i linii"
#  validates_is_unique :stop_id, :scope => :line_id, :message => "Taki rozkład już istnieje"
#  validates_with_method :check_timetables
#  default_scope(:default).update(:order => [:nice])

  private

  ##
  # Validation: Rozkład musi posiadać co najmniej jedną niepustą tabelę
  def check_timetables
    if not (self.table1.blank? and self.table2.blank? and self.table3.blank?)
      true
    else
      [false, "Nie podano żadnych danych"]
    end
  end

  public

  def self.day(date)
    case date.wday
      when 1..5 ; 0
      when 6    ; 1
      when 0    ; 2
    end
  end

#  alias_method :dm_line, :line
#
#  def line
#    Timetable.repository(repository.name){
#      dm_line
#    }
#  end
  def line
    @line ||= Line.get line_id
  end

  def stop
    @stop ||= Stop.get stop_id
  end

  def line_no
    line.no
  end


  ##
  # Wywołuje blok dla każdego istniejącego rozkładu
  # Przekazuje parametry: minutes, index
#  def each(&block)
#    3.times do |i|
#      block.call minutes_by_table_no(i), i unless minutes_by_table_no(i).blank?
#    end
#    nil
#  end

  ##
  # Input: Date
  # Output<Array of Integer>: Rozkład jazdy dla danego dnia
  def minutes(date)
    time[Timetable.day(date)] # || raise("Request for not existing table")
  end

  def minutes_by_table_no(no)
    time[no] || raise("Request for not existing table")
  end

  ##
  # Input: dzień, numer kursu
  # Output: suma minut od pierwszego do n-tego kursu
  def minutes_sum(date, n = -1)
    return 0 if minutes(date)[0..n].all?{|m| m.nil?}
    start*60 + minutes(date)[0..n].inject{|x,y| x.to_i + y.to_i}.to_i
  end

  ##
  # Input: Numer rozkładu
  # Output: minutes_sum
  def minutes_sum_by_table_no(no, n = -1)
    return 0 if minutes_by_table_no(no)[0..n].all?{|m| m.nil?}
    start*60 + minutes_by_table_no(no)[0..n].inject{|x,y| x.to_i + y.to_i}.to_i
  end

  ##
  # Wszystkie rozkłady na trasie linii
  def timetables
    line.timetables
  end

  def nextinline=(timetable)
    @nextinline = timetable
  end

  ##
  # Output<Timetable>: Następny rozkład jazdy
  def nextinline

    raise "Undefined nice index" unless nice
    @nextinline ||= Timetable.by_line(:key => [line_id, nice+1]).first

#    unless @nextinline
#      @nextinline = Timetable.first( :line_id => line_id, :nice.gte => nice+1, :level.lte => level, :order => [:nice])

#    end
#    if @nextinline
#      @nextinline.previnline = self
#    else
#      t1,t2,t3 = nil
#
#      if table1
#        t1 = table1.dup
#        i=0
#        i+=1 while t1[i].nil?
#        t1[i] += 1
#      end
#
#      if table2
#        t2 = table2.dup
#        i=0
#        i+=1 while t2[i].nil?
#        t2[i] += 1
#      end
#
#      if table3
#        t3 = table3.dup
#        i=0
#        i+=1 while t3[i].nil?
#        t3[i] += 1
#      end
#
#      @nextinline = Timetable.new(:start => start, :table1 => t1, :table2 => t2, :table3 => t3, :stop_id => line.direction.id)
#      @nextinline.previnline = self
#    end
#
#    @nextinline
  end

  def alternate_nextinline
    Timetable.first( :line_id => line_id, :nice => nice+1, :level => level+1)
  end

  def nextinline=(timetable)
    @nextinline = timetable
  end

  ##
  # Output<Timetable>: Poprzedni rozkład jazdy
  def previnline
    unless @previnline
      @previnline = Timetable.first( :nice => nice-1, :line_id => line_id )
      #@previnline.nextinline = self if @previnline
    end
    @previnline
  end

  def previnline=(timetable)
    @previnline = timetable
  end

  ##
  # Output<Timetable>: Rozkład dla przeciwnej linii
  def opposite
    @opposite ||= Timetable.first :line_id => line.opposite.id, 'stop.name' => stop.name if line.opposite
  end

  ##
  # Nazwa następnego przystanku
  def next_stop_name
    @next_stop_name ||= (
      if nextinline
        nextinline.name
      else
        line.direction_name
      end
    )
  end

  ##
  # Zwraca obiekt Polyline
  def polyline
    # stop.polylines.select{|x| x.end == nextinline.stop rescue false}.first
    p = Polyline.first :beg_id => stop_id, :end_id => (nextinline.stop_id rescue line.direction.id)
    p.line = line.id if p
    p
  end

  ##
  # Output:<Polyline or false>: Zgaduje obiekt Polyline na podstawie przeciwnej linii
  def new_polyline
    return false if line.bus?
    return false unless line.opposite
    if nextinline
      p = nextinline.stop.opposite.map{|x| x.timetables.select{|y| y.nextinline.stop.name == stop.name rescue false}.map{|y| y.polyline}}.flatten.compact.last
    else
      p = line.opposite.timetables.first.polyline
    end

    if p
      p.beg_id = stop_id
      p.line = line.id
      p
    else
      false
    end
  end

  ##
  # Input: dzień
  # Output<Time>: Godzina pierwszego kursu
  def first(date)
    raise "Brak kursów dnia: " << date.to_s if minutes(date).empty?
    absolute_arrival date, 0
  end

  ##
  # Input: dzień
  # Output<Time>: godzina ostatniego kursu
  def last(date)
    raise "Brak kursów dnia: " << date.to_s if minutes(date).empty?
    absolute_arrival date, -1
  end

  ##
  # Input: dzień
  # Output<Integer>: Całkowita liczba kursów
  def runs(date)
    minutes(date).compact.size
  end

  ##
  # Ouptut: Array
  # indeksy kursów, które nie jadą z pętli
  def change_me(date)
    out = []
    i = 0
    minutes(date).each do |row|
      row.each do |min|
        out << i if min.nil?
        i += 1
      end
    end
  end

  ##
  # Input: data, numer odjazdu
  # Output<Array>: minuty, które pozostały do odjazdu w czasie time. [] gdy brak rozkładu dla danego dnia lub gdy ostatni pojazd zajechał do zajezdni
  def nextruns(time = Time.now, n = nil)
    min = (minutes(time) rescue nil)
    return [] if min.blank?

    now = (time.hour - start) * 60 + time.min
    sums = []
#     minutes(time).size.times{|i| sums << minutes_sum(time, i)}
    sum = 0
    minutes(time).compact.each do |m|
      sum += m
      sums << sum
    end

    sums = sums.select{|x| x >= now}.map{|x| x - now}.select{|x| x < 60}
    sums = sums.first(n) if n
    sums
  end

  # Zwraca numer następnego kursu i czas za jaki odjedzie
  def nextrun(time)

    min = minutes(time)
    return [] if min.blank?

    now = (time.hour - start) * 60 + time.min

    sum = 0
    min.each_with_index do |m,i|
      next if m.nil?
      sum += m
      return [sum - now, i] if sum >= now 
    end

  end

  ##
  # Input<Date, Integer>: data, numer kursu w zakresie od 1 do line.runs.last
  # Output<Time>: czas przyjazdu n-tego kursu danego dnia
  def arrival(date, n)
    raise ArgumentError if minutes(date)[n].nil?
    Time.parse(date.strftime('%d-%m-%Y')) + (minutes_sum(date, n) * 60)
  end

  ##
  # Input<Date, Integer>: Bezwzględny numer kursu dla tego rozkładu, dzień
  # Output<Time>: Godzina danego kursu jako obiekt Time
  # TODO: metoda Time.parse nie jest najszybszą funkcją Rubiego
  def absolute_arrival(date, n)
    Time.parse(date.strftime('%d-%m-%Y')) + (minutes(date).compact[0..n].inject { |x,y| x + y }.to_i * 60) + start * 3600
  end

  ##
  # Output: Prędkość w minutach
  # Należy uważać, aby n-ty kurs nie był nil
  def speed(date, n)
    if nextinline
      ((nextinline.arrival(date, n) - arrival(date, n)) / 60).to_i
    else
      opposite.previnline.speed(date, n)
    end
  end

  ##
  # Output<Integer>: średni czas w minutach jaki jest potrzebny aby przejechać z danego przystanku do następnego w linii
  # TODO: You can do betten than that.
  def avg_speed(date)
#    Merb::Cache[:memcached].fetch "Timetable:" + id.to_s + ":avg" do
      sum = 0.0
      acc = 10
      r = line.runs(date) / acc # co jak < 2 ? Odp iteracja po każdej jeździe
      acc.times do |i|
        n = i*r
        if ((s = speed(date, n)) > 0 rescue false)
          sum += s
        else
          acc -= 1
        end
      end
      (sum / acc unless acc == 0) || 0
#    end
  end

  ##
  # Input<Integer>: Time
  # Output<Integer>: Względny numer kursu
  # weź również pod uwagę specyfikację rozkładów (złożoność obliczeniowa)
  # TODO SPEC: do testów należy dodać coś takiego: sprawdź czy time = arrival(run) zgadza się z run == run_number(time) ?
  # TODO optymalizacja tzn złożoność != n
  # SUPER SLOW!!!
  def run_number(time)
    now = time.hour * 60 + time.min
    runs(time).times do |i|
      return i if minutes_sum(time, i) == now
    end
    raise ArgumentError
  end

  ##
  # Output: { "Dni powszednie" => [Array of Strings], ...}
  def to_arr
    out = {}
    description = []
    days = ["Dni powszednie", "Soboty", "Święta"]
    days.each.with_index do |day, i|
      unless (min = minutes_by_table_no(i)).blank?
        lines = [[]]
        sum = 0
        min.each_with_index do |m,k|
          next if m.nil?
          sum += m
          (sum / 60).times do |j|
            lines << []
          end
          sum = sum % 60
          lines.last ||= ""
          lines.last << ("%02d" % sum)
          char = 64
          line.description(i).each_pair do |des, idx|
            char += 1
            if idx.include?(k) and (des[1] >= nice rescue true)
              lines.last.last << char.chr
              joint = [char.chr,des.first].join(" - ")
              description << joint unless description.include?(joint)
            end
          end
        end
        out[day] = lines.map!{|x| x.empty? ? ["-"] : x }
      end
    end
    size = 0
    out.each_value{|x| size = x.size if x.size > size}
    out.each_value{|x| (size - x.size).times{x << ["-"]}}
    out[:description] = description.sort
    out
  end
end