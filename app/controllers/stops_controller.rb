# encoding: utf-8

class StopsController < ApplicationController
#  provides :ajax, :js, :json
   
#  layout :standard
#  cache :index, :unless => :authenticated?
#  eager_cache :create, :index, :uri => '/all-stops.ajax'
#  eager_cache :delete, :index

#  before :ensure_authenticated, :exclude => [:index, :show, :departures, :search, :search_by_name]

  def index #(format, type = nil, only = "id,name,location,lng,lat,buses,trams", limit = 100, offset = 0)

#    @type = type
    @types = {"all" => "wszystkie", "tram" => "tramwajowe", "bus" => "autobusowe"}
#
#    @stops = case type
#      when "bus"
#        Stop.buses
#      when "tram"
#        Stop.trams
#      else
#        Stop.all
#    end

    @stops = Stop.by_name(:limit => 20)

#    render :action => 'index' #@stops #, :only => only.split(",").map{|x| x.to_sym} # , :methods => [:linie]
  end

  def show #(id)

    @timetables = Timetable.by_stop(:startkey => [params[:id]], :endkey => [params[:id], {}])
    raise NotFound unless @stop = Stop.new(@timetables.shift)

    @opp = @stop.opposite
    @all = Stop.count
    @directions = {}
    @unknown = []
    @time = Time.now

    @timetables.each do |timetable|
#      line = timetable.line
      if s = timetable['next'] #|| line.direction
        @directions[s] ||= []
        @directions[s] << timetable
      else # Unknown direction
        @unknown << timetable #line
      end

#      if (s = timetable.alternate_nextinline.stop rescue nil)
#        @directions[s] ||= []
#        @directions[s] << line
#      end
    end

    @directions = @directions.map{|x,y| [Stop.get(x), y.sort_by{|z| z['line']}]}.sort_by{|x,y| y.size}.reverse 

#    render @stop, {:only => [:id, :name, :location, :lng, :lat, :buses, :trams]}
  end

  def departures(id)
    only_provides :json
    @stop = Stop.get(id)
    raise NotFound unless @stop

    render @stop.departures.map{|x| {:id => x[:timetable].id, :m => x[:minutes_left]}}, :layout => false
  end

  def new
    only_provides :html, :ajax
    @stop = Stop.new

    if request.xhr?
      render @stop, :layout => false
    else
      render @stop
    end
  end

  def edit(id)
    only_provides :html, :ajax, :js
    @stop = Stop.get(id)
    raise NotFound unless @stop

    display @stop
  end

  def create(stop, format)

    stop[:lat] = stop[:lat].to_f
    stop[:lng] = stop[:lng].to_f   

    @stop = Stop.new(stop)
    if @stop.save
      redirect resource(@stop, :format => format), :message => {:notice => "Dodano przystanek"}
    else
      message[:error] = "Stop failed to be created"
      render :new
    end
  end

  def update(id, stop, format)
    @stop = Stop.get(id)
    raise NotFound unless @stop
    if @stop.update_attributes(stop)
       redirect resource(@stop, :format => format), :message => {:notice => "Zaktualizowano przystanek"}
    else
      render @stop, :edit
    end
  end

  def delete(id, format)
    @stop = Stop.get(id)
    raise NotFound unless @stop
    if @stop.destroy
      redirect resource(:stops, :format => format), :message => {:notice => "Usunięto przystanek"}
    else
      raise InternalServerError
    end
  end

  def misplaced(id)
    only_provides :ajax
    
    @stop = Stop.get(id)
    raise NotFound unless @stop

    render @stop

  end

  def search(q, only = "id,name,location")
    only_provides :json

    @stops = Stop.search :conditions => [q]
    render @stops, :only => only.split(",").map{|x| x.to_sym}, :methods => [:print_nextstops]
  end

  def search_by_name(q, only = "id,name")
    only_provides :json

    @stops = Stop.all :name => q
    display @stops #, {:only => only.split(",").map{|x| x.to_sym}, :methods => [:print_nextstops]}
  end

  def timetables #(id, only = "id,line_id")
#    only_provides :json

    @stop = Stop.get(params['id'])
    raise NotFound unless @stop
    @timetables = @stop.timetables #.sort_by{|x| x.line.no}

    only = "_id,line"

    respond_to do |format|
#      format.html # index.html.erb
      format.json  { render :json => @timetables }
    end

#    display @timetables #, :only => only.split(",").map{|x| x.to_sym}
  end

  #def timetables(id, only = "id,line_id")
  #  only_provides :json
  #
  #  @stop = Stop.get(id)
  #  raise NotFound unless @stop
  #
  #  @timetables = @stop.timetables.sort_by{|x| x.line.no}

    #display @timetables, :only => only.split(",").map{|x| x.to_sym}

    #display @stop, :only => only.split(",").map{|x| x.to_sym}

    # display @locations, :except => [:locatable_type, :locatable_id], :include => [:locatable]
  #end
end # Stops
