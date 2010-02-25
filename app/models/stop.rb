##
# Klasa reprezentująca fizyczny przystanek
class Stop < CouchRestRails::Document
  use_database :podsadzacz

#  has n,      :timetables #, :dependent => :destroy
#  has n,      :lines, :through => :timetables
#  has n,      :polylines, :child_key => [:beg_id]

  property    :id
  property    :name     # String,   :length => (3..50), :message => "Nieprawidłowa nazwa przystanku"
  property    :lat      # Float #,    :precision => 10, :scale => 8, :in => (-90..90),   :message => "Szerokość geograficzna musi zawierać się pomiędzy -90, a 90."
  property    :lng      # Float #,    :precision => 10, :scale => 8, :in => (-180..180), :message => "Długość geograficzna musi zawierać się pomiędzy -180, a 180."
  property    :location # String
  property    :buses    # Boolean,  :default => false
  property    :trams    # Boolean,  :default => false

  timestamps!

  view_by :name, :map =>
    "function(doc){
      if (doc['couchrest-type'] == 'Stop' && (doc.buses || doc.trams)){
        emit(doc.name, doc)
      }
    }"

  view_by :id, :map =>
    "function(doc){
      if (doc['couchrest-type'] == 'Stop'){
        emit(doc.id, doc)
      }
    }"

  view_by :line, :map =>
    "function(doc){
      if (doc['couchrest-type'] == 'Line'){
        emit([doc['_id']], doc)
      }
      if (doc['couchrest-type'] == 'Timetable'){
        emit([doc.line_id, doc.nice], {\"_id\": doc.stop_id, \"next2\": doc.next})
      }
    }"
#  , :reduce =>
#    "function(keys, values, rereduce){
#
#      function decodeLine (encoded) {
#        var len = encoded.length;
#        var index = 0;
#        var array = [];
#        var lat = 0;
#        var lng = 0;
#
#        while (index < len) {
#          var b;
#          var shift = 0;
#          var result = 0;
#          do {
#            b = encoded.charCodeAt(index++) - 63;
#            result |= (b & 0x1f) << shift;
#            shift += 5;
#          } while (b >= 0x20);
#          var dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
#          lat += dlat;
#
#          shift = 0;
#          result = 0;
#          do {
#            b = encoded.charCodeAt(index++) - 63;
#            result |= (b & 0x1f) << shift;
#            shift += 5;
#          } while (b >= 0x20);
#          var dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
#          lng += dlng;
#
#          array.push([lat * 1e-5, lng * 1e-5]);
#        }
#
#        return array;
#      }
#
#      function distance(lat1,lon1,lat2,lon2) {
#        var R = 6371;
#        var dLat = (lat2-lat1) * Math.PI / 180;
#        var dLon = (lon2-lon1) * Math.PI / 180;
#        var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
#          Math.cos(lat1 * Math.PI / 180 ) * Math.cos(lat2 * Math.PI / 180 ) *
#          Math.sin(dLon/2) * Math.sin(dLon/2);
#        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
#        return R * c;
#      }
#
#      if(!rereduce){
#
#        var length = 0
#
#        for(var i=0; i<values.length; i++){
#          var points = decodeLine(values[i].replace(/\\\\/g, '\\'))
#          var prev = points.shift()
#          for(var j=0; j<points.length; j++){
#            length += distance(prev[0], prev[1], points[j][0], points[j][1])
#            prev = points[j]
#          }
#        }
#
#        return length
#
#      } else {
#        return sum(values)
#      }
#    }"

  view_by :updated_at, :map =>
    "function(doc){
      if (doc['couchrest-type'] == 'Stop'){

        var type = 0
        if(doc.buses){
          if(doc.trams){
            type = 3
          } else {
            type = 2
          }
        } else if(doc.trams) {
          type = 1
        }

        emit([doc['updated_at']], {n: doc.name, l: doc.location, lng: doc.lng, lat: doc.lat, t: type})
      }
    }"

#  before :destroy do
#    throw :halt unless timetables.empty?
#  end

#  before :valid? do
#    prec = 10**7
#    self.lat = (self.lat * prec).round.to_f / prec
#    self.lng = (self.lng * prec).round.to_f / prec
#  end
    
#  after :save do
    #log = File.open('/home/wasiutynski/www/mpk/log/stops.log', 'a')
    #log << (self.to_json << ",\n")
    #log.close
#  end

  def lines
    [] #timetables.map{|t| t.line}
  end

  def timetables
    Timetable.by_stop :startkey => [self['_id'], 0], :endkey => [self['_id'], {}]
  end

  ##
  # Output<Array of Stops>: Przystanki z których odjeżdzają tramwaje
  def self.trams
    # all(:order => ["name"]).select{|x| x.tram?}
    all(:trams => true)
  end

  ##
  # Output<Array of Stops>: Przystanki z których odjeżdzają autobusy
  def self.buses
    # all(:order => ["name"]).select{|x| x.bus?}
    all(:buses => true)
  end

  def hub
#    Hub.first(:name => name) || Hub.new(:name => name)
    Stop.by_name(:startkey => name, :endkey => name)
  end

  def opposite
    hub.select{|s| s['_id'] != self['_id']}
  end

  ##
  # Output<Integer>: liczba pojazdów zatrzymujących się na przystanku w danym dniu o danej godzinie
  def vph(date)
    out = 0
    timetables.each do |t|
      out += 60 / t.line.okres(date) unless t.line.okres(date) == 0
    end
    out
  end

  ##
  # Output<Integer>: zasięg jako ilość przystanków do których można bezpośrednio dojechać z danego przystanku
  def range
    lines.map{|x| x.stops}.flatten.uniq.size
  end

  ##
  # Output<Integer>: zasięg w procentach, wszystkich przystanków w bazie danych
  # TODO: stopień penetracji jako argument
  def percent_range
    (range.to_f / Stop.count * 1000).round / 10.0
  end

  ##
  # Output<Array of Stops>: przystanki, bezpośrednio połączone. Tj. kolejne przystanki conajmniej jednej z linii
  def nextstops
#    @nextstops ||= Stop.all :id => (Merb::Cache[:memcached].fetch "Stop:" + id.to_s + ":nextstops" do
      timetables.map{|x| x.nextinline ? x.nextinline.stop : x.line.direction }.uniq.compact
#    end)
  end

  def nextstops_names
#    Merb::Cache[:memcached].fetch "Stop:" + id.to_s + ":nextstops_names" do
      nextstops.map{|x| x.name}.uniq
#    end
  end

  ##
  # Output<String>: lista nazw nextstops, połączona przecinkami
  def print_nextstops
    nextstops_names.empty? ? "brak" : nextstops_names.join(", ")
  end

  ##
  # Output<Array of Stops>: przystanki, bezpośrednio połączone. Tj. poprzednie przystanki conajmniej jednej z linii
  def prevstops
#    @prevstops ||= Stop.all :id => (Merb::Cache[:memcached].fetch "Stop:" + id.to_s + ":prevstops" do
      timetables.map{|x| x.previnline.stop_id rescue nil}.uniq.compact
#    end)
  end

  def prevstops_names
#    Merb::Cache[:memcached].fetch "Stop:" + id.to_s + ":prevstops_names" do
      prevstops.map{|x| x.name}.uniq
#    end
  end

  ##
  # Output<String>: lista nazw prevstops, połączona przecinkami
  def print_prevstops
    prevstops_names.empty? ? "brak" : prevstops_names.join(", ")
  end

  ##
  # Output<String>: nazwy: poprzednich przystanków, bierzącego oraz następnych
  def surrounding
    print_prevstops + " &rarr; " + name + " &rarr; " + print_nextstops
  end

  ##
  # Ta metoda nie powinna istnieć, gdyż w domyślnej tabeli przechowuję tylko aktywne obiekty (linie)
  def _lines
    lines.select{|x| x.active}
#     timetables.map{|x| x.line}
  end

  ##
  # Output<Integer>: typ pojazdów obsługujących przystanek
  # * 0 - przystanek nieczynny
  # * 1 - przystanek tramwajowy
  # * 2 - przystanek autobusowy
  # * 3 - przystanek autobusowo-tramwajowy
  def typ
    if trams and buses
      3
    elsif buses
      2
    elsif trams
      1
    else
      0
    end
  end

  ##
  # Output<Bool>
  # Notice: docelowo dwie bazy dla aktywnych i nieaktywnych
  def active?
    trams or buses
  end

  ##
  # Output<Array>: najbliższe odjazdy
  # Input: liczba najbliższych odjazdów, czas
  def departures(time = Time.new, n = 2)
    out = []
    timetables.each do |t|
      out << {:line => t.line.no ,:timetable => t, :minutes_left => t.nextruns(time, n)}
    end
    out.select{|x| not x[:minutes_left].empty?}.sort_by{|x| x[:minutes_left].first}
  end

  ##
  # Output<Float>: Kąt w stopniach, jako liczba zmiennoprzecinkową z zakresu (0..360), który tworzy równik z odcinkiem łączącym dwa przystanki
  # Input: identyfikator przystanku
  # TODO .round.abs
  # angle = (360 - angle) if angle > 180
#   def angle(stop_id)
#     stop = Stop.get stop_id
#     a = stop.lat - lat
#     b = stop.lng - lng
#     c = Math.sqrt(a**2 + b**2)
#     if(b > 0) # I lub II ćwiartka
#       Math.acos(a/c) / Math::PI*180
#     else # III lub IV ćwiartka
#       (2*Math::PI - Math.acos(a/c)) / Math::PI*180
#     end
#   end

  ##
  # Notice: wyłącznie na potrzeby serializacji json. Dziwne.
  #def linie
  #  timetables.map{|x| {:no => x.line.no, :id => x.id, :line_id => x.line.id} }.sort_by{|x| x[:no]}
  #end

  ##
  # Output: Hash of urls to all mantained charts
  def gchart(date)
#     Merb::Cache[:memcached].fetch "Stop:" + id.to_s + ":gcharts" do


      out = {}

#      GoogleChart::LineChart.new('800x200', "Czas oczekiwania na przystanku: " + name + " (w minutach)", false) do |b|
#
#        start = timetables.map{|x| x.first(date) rescue nil}.compact.min
#        time = start
#
#        i=0
#        data = []                 # Minuty do odjazdu po każdej godzinie
#        while time.hour < 23
#          timetables.each do |t|
#            data << t.nextruns(time).map{|x| x + i*60}
#          end
#          i += 1
#          time += 1.hour
#        end
#
#        data = data.flatten.sort
#        last = 0
#        data.map! do |x|
#          x = x - last
#          last = x + last
#          x
#        end
#
#        b.data "Czas", data
#        b.show_legend = false
#        b.axis :y, :labels => [0, data.max]
#        b.axis :x, :labels => [start, time].map{|x| x.strftime("%H:%M")}
#
#        out[:waiting] = b.to_url #(:chbh=>"a")
#      end unless timetables.empty?
#
#      GoogleChart::Base.new('200x200', 'Przystanek x') do |b|
#        out[:qr_code] = b.to_url(:cht=>"qr", :chl=>"test")
#      end

      out
#     end
  end

end
