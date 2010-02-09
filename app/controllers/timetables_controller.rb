# encoding: utf-8

class TimetablesController < ApplicationController

#  only_provides :json

#  cache :index, :show

  def index #(line_id)
#    provides :html, :ajax, :js


    @stops = Stop.by_line(:startkey => [params['line_id']], :endkey => [params['line_id'], {}])

    @line = Line.new @stops.shift
    raise NotFound unless @line

#    @alternate_direction = @line.alternate_direction

  end

  def show #(id)
#    provides :html

    @timetable = Timetable.by_line_stop(:key => [params['line_id'], params['id']], :limit => 1).first 
    raise "NotFound" unless @timetable

    @stops = Stop.by_line(:startkey => [@timetable.line_id], :endkey => [@timetable.line_id, {}])
    @stop = @stops[@timetable.nice]
    @line = Line.new @stops.shift

#    @start = - @timetables.index(@timetable)
    @data = @timetable.to_arr
    @description = @data.delete(:description)
#    @alternate_direction = @line.alternate_direction

#    display @timetable, :layout => "timetable"
    render :layout => 'timetable'
  end

  # Pozwala zmienić przystanek rozkładu
  def update(id, stop_id)
    @timetable = Timetable.get(id)
    raise NotFound unless @timetable
    if @timetable.update_attributes({:stop_id => stop_id})
      render({:stop_id => stop_id}.to_json, :layout => false) #redirect resource(@timetable)
    else
      render "Błąd", :layout => false #display @timetable, :edit
    end
  end

  # Następny rozkład jazy
  def next

  end

  # Najbliższe odjazdy
  # Input: Ilość, Czas
  def departures(n = nil, time = Time.now)
    
  end

  # Zwraca <Hash>: {:day => (0..2), :run => n}
  def next_run_number(id)

    timetable = Timetable.get(id)
    raise NotFound unless timetable
    time = Time.now

    out = {}
    out[:day] = Global.day(time)

    sum = timetable.start * 60
    now = time.hour * 60 + time.min
    timetable.minutes(time).compact.each_with_index do |min, i|
      sum += min
      if sum > now
        out[:run] = i+1
        break
      end
    end

#    out[:run] = timetable.minutes(time)[0..timetable.run_number(time + timetable.nextruns(time, 1)[0] * 60)].compact.size
    display out
  end

#  def stop(stop_id, only = "id,line_id")
#    only_provides :json
#
#    stop = Stop.get(stop_id)
#    raise NotFound unless stop
#    @timetables = stop.timetables #.sort_by{|x| x.line.no}
#
#    display @timetables, :only => only.split(",").map{|x| x.to_sym}, :methods => [:line_no]
#  end
end # Timetables