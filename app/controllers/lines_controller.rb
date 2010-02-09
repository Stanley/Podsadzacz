# encoding: utf-8

require "cgi"

class LinesController < ApplicationController
#  provides :ajax, :js, :json

#   if request.html? then 'standard' end 

#  before :ensure_authenticated, :exclude => [:index, :show, :show_by_no]
#  layout :standard
#  cache :index, :show

  def index #(format, active = 'active', type = 'all')

#    @type = type
#    if active == "inactive"
#      @active = false
#    else
#      @active = true
#    end

    @types = {"all"       => "wszystkie",
              "tram"      => "tramwajowe",
              "bus"       => "autobusowe",
              "zonalBus"  => "aglomeracyjne",
              "nightBus"  => "nocne"}

#    repository(@active ? :default : :archive) do
#      lines = case @type
#        when "tram"
#          Line.trams
#        when "bus"
#          Line.buses
#        when "zonalBus"
#          Line.buses.select{|x| x.zonalBus?}
#        when "nightBus"
#          Line.buses.select{|x| x.nightBus?}
#        else
#          Line.all
#      end
#

    @lines = Line.by_dest(:limit => 10,:reduce => true, :group => true, :group_level => 1)['rows']

#    @arr = {}
#    line = nil
#    json.each do |row|
#      if(row['couchrest-type'] == "Line")
#        line = row
#      else(row['couchrest-type'] == "Timetable")
#        @arr[line.no] ||= []
#        @arr[line.no] << [line['_id'], row['hub'], line.direction || "nieznany"]
#        line = nil
#      end
#    end


#     if request.xhr?
#       display @lines, :layout => false
#     else
#      display @lines
# render @lines
#     end
  end

  def show #(format, id, date = nil)

    @line = Line.get(params['id'])
    raise NotFound unless @line

    @date =
      if true #date.nil?
        @line.begin_date
      else
        #d = Date.parse(date)
        #raise "Błąd" unless @line.period.include? d
        #d
      end

#    if request.xhr?
#      display @line, :layout => false
#    else
#      display @line
#    end

  end

#  def show_by_no(no, direction, format, date = nil)
#    line = Line.all(:no => no).select{|x| x.direction_name == CGI::unescape(direction) && x.period.include?(date.nil? ? Date.today : Date.parse(date))}.first
#    raise NotFound unless line
#    redirect resource(line, :format => format, :date => date)
#  end

  def new
    only_provides :ajax
    @line = Line.new
    if request.xhr?
      display @line, :layout => false
    else
      display @line
    end
  end

  def recreate(line)
    only_provides :ajax, :js

    @routes = []
    @no = line['no']
    @date = line["begin_date"]
    routes = Mpk.route(@no, @date)
    dst = "?" # TODO: kierunek linii
    used = []
    i = 1

    routes.each do |route|
      @routes << {}
      route.each_pair do |r, stops|

        stops = stops.sort
        next_stop = stops.shift
        prev_stop = ''
        latest_archived = (Line.latest_archived(@no, next_stop.last).timetables rescue [])
        results = {}

        while stop = next_stop
          next_stop = stops.shift
          next_stop_name = next_stop.last unless next_stop.nil?
          stop_name = stop.last
          selected = []
          selected = latest_archived.map{|x| x.stop}.select{|x| x.name == stop_name}

          if selected.empty?
            all = Stop.search(:name => "^" + stop_name + "$").select{|s| @no.to_i < 100 ? s.trams == true : s.buses == true}
            Merb.logger.info "Brak przystanku " + stop_name + " w bazie danych" if all.empty?
            # Wyberz tylko te przystanki, których następne i proprzednie zgadzają się z bierzącą linią
            if all.size < 2
              selected = all
            else
              selected = all.select{|x| x.print_nextstops.include?(next_stop_name || dst) and x.print_prevstops.include?(prev_stop)}
              # Wybierz tylko te przystanki którch następne i poprzednie nie są poprzednimi lub następnymi
              selected = all.select{|x| not (x.print_nextstops.include?(prev_stop) or x.print_prevstops.include?(next_stop_name || dst))} if selected.empty?
              selected = all if selected.empty?
            end
          end

          prev_stop = stop_name
          results[stop.first] = selected
          i+=1
        end
        @routes.last[r] = results
      end
    end

    display @routes
  end

  def edit(id)
    only_provides :html, :js, :ajax
    @line = Line.get(id) || repository(:archive){ Line.get(id) }
    raise NotFound unless @line

    if request.xhr?
      display @line, :layout => false
    else
      display @line
    end
  end

  def auto_create(line_no, stops, date, format)
    transaction = Line.auto_create line_no, stops, date
    redirect resource(:lines, :format => format), :message => {:notice => "Line was successfully created. " << transaction.inspect}
  end

  def update(id, line, format, polylines = {})
    @line = Line.get(id) || repository(:archive){ Line.get(id) }
    raise NotFound unless @line

    line[:end_date] = nil if line[:end_date].empty?

    unless polylines.blank?
      require 'merb/gmap_polyline/gmap_polyline_encoder.rb'
      encoder = GMapPolylineEncoder.new()

      # Należy usawić run aby był bardziej universalny i szybki
#       run = @line.runs.last / 2
#       while(@line.specialsIndexes.include?(run) or @line.shortersIndexes.include?(run)) do
#         run += 1
#       end

      length = 0
      timetables = @line.timetables.dup

      polylines.each_pair do |stop_id, value|

#         stops = timetables.map{|x| x.stop_id}[key.to_i,2]
#         timetable = timetables.select(:stop_id => key) #timetables[key.to_i]
        i = timetables.map{|x| x.stop_id}.index(stop_id.to_i)
        raise "coś nie tak" unless i
        timetable = timetables.delete_at(i) #timetables[i] # delete_at indeks
        code = (encoder.encode( value[1..-2].split(")(").collect{|x| x.split(", ").collect{|y| y.to_f}}) rescue {})

        polyline = Polyline.first_or_create :beg_id => stop_id, :end_id => (timetable.nextinline.stop_id rescue @line.direction.id)
        polyline.points = code[:points]
        jeden = code[:points]
        polyline.levels = code[:levels]
        polyline.save!

        #Merb.logger.info(jeden + " =? " + polyline.points)
        raise "błąd" if jeden != polyline.points
        @date = @line.begin_date

        avg = timetable.avg_speed(@date)
        timetable.ratio = avg > 0 ? polyline.length / (avg / 60) : 0 # km/h # należy się przyjżeć dlaczego zwraca -1; .abs => workaround
        timetable.save!

        length += polyline.length
      end
      # (nie uaktualnia w trybie html)
       line[:length] = (length * 100).round / 100.0
    end

    if @line.update_attributes(line)
      #if request.xhr?
      #  @date = @line.begin_date
      #  message[:notice] = "Line was successfully updated"
      #  render :show, :layout => false
      #else
        redirect resource(@line, :format => format), :message => {:notice => "Linia zaktualizowana"}
      #end
    else
      #display @line, :edit
      raise "todo"
    end
  end

  def delete(id)
    @line = Line.get(id)
    raise NotFound unless @line
    if @line.destroy
      redirect resource(:lines), :message => {:notice => "Line was successfully destroyed."}
    else
      raise InternalServerError
    end
  end
end # Lines
