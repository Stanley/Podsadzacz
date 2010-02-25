class Polyline < CouchRestRails::Document
  use_database :podsadzacz

#  belongs_to :beg, :class_name => "Stop", :child_key => [:beg_id]
#  belongs_to :end, :class_name => "Stop", :child_key => [:end_id]

  # reproperty :id      #,       Serial
  property :beg_id  #,   Integer
  property :end_id  #,   Integer
  property :points  #,   Text
  # property :levels  #,   String
  
  #validates_present :beg_id, :points, :levels
  #validates_is_unique :beg_id, :scope => :end_id

#  def to_json
#    {:color => (self.color rescue "#000")}.merge(self.attributes).to_json
#  end

#  def line=(line_id)
#    @line_id = line_id
#  end

  view_by :line,
    :map => "function(doc){
      if (doc['couchrest-type'] == 'Timetable'){
        emit([doc.line_id, doc.nice], {\"_id\": (doc.stop_id.substr(0,16) + doc.next.substr(0,16)), \"color\": doc.ratio})
      }
    }"
#    :reduce => "function(keys, values, rereduce){
#
#    }"

#  def color(line)
#    ratio = Timetable.first(:stop_id => beg_id, :line_id => line).ratio || 0
#    rank = (ratio - 5) / (40 - 5)
#    if rank < 0
#      out = "#ff0000"
#    elsif rank < 1
#      out = "#" + sprintf("%02x", (1-rank)*256) + "00" + sprintf("%02x", rank*256)
#    else
#      out = "#0000ff"
#    end
#    out
#  end
#
#  ##
#  # Output: Długość linii w ?jakich? jednostkach
#  def length
##    require 'merb/gmap_polyline/gmap_polyline_decoder.rb'
#    return 0 if points.blank?
#    arr = PolylineDecoder.new.decode(points.gsub("\\\\", "\\"))
#    r = 6371
#    toRad = 3.142 / 180
#    out = 0.0
#    odc1 = []
#    for odc2 in arr
#      unless odc1.empty?
#        dLat = (odc2[0]-odc1[0]) * toRad;
#        dLon = (odc2[1]-odc1[1]) * toRad;
#
#        a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
#            Math.cos(odc1[0] * toRad) * Math.cos(odc2[0] * toRad) *
#            Math.sin(dLon / 2) * Math.sin(dLon / 2);
#        c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
#        d = r * c;
#        out += d
#      end
#      odc1 = odc2
#    end
#  return out
#  end
end
