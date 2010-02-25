# encoding: utf-8

class StopsController < ApplicationController

  respond_to :json, :except => :edit
  respond_to :html, :except => :timetables

#  cache :index, :unless => :authenticated?
#  eager_cache :create, :index, :uri => '/all-stops.ajax'
#  eager_cache :delete, :index

#  before :ensure_authenticated, :exclude => [:index, :show, :departures, :search, :search_by_name]

  def index

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

    @stops = if(params['q'])
      Stop.search("by_name", params['q'], :limit => params['limit'] || 20)['rows']
    else
      Stop.by_name(:limit => 0)
    end

    respond_with @stops
  end

  def show

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

    respond_with @stop.only('_id', 'name', 'location', 'lng', 'lat', 'buses', 'trams')
  end

#  def departures(id)
#    only_provides :json
#    @stop = Stop.get(id)
#    raise NotFound unless @stop
#
#    render @stop.departures.map{|x| {:id => x[:timetable].id, :m => x[:minutes_left]}}, :layout => false
#  end

  def new
    @stop = Stop.new
  end

  def edit
    @stop = Stop.get(params[:id])
    raise NotFound unless @stop
  end

  def create

    stop[:lat] = stop[:lat].to_f
    stop[:lng] = stop[:lng].to_f   

    @stop = Stop.new(stop)
    if @stop.save
      flash[:notice] = "Dodano przystanek"
      redirect_to stop_path(@stop)
    else
      flash[:error] = "Stop failed to be created"
      render :new
    end
  end

  def update

    @stop = Stop.get(params['id'])
    raise NotFound unless @stop

    if @stop.update_attributes(params['stop'])
      flash[:notice] = "Zaktualizowano przystanek"
      redirect_to stop_path(@stop['_id']) 
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
    @stop = Stop.get(id)
    raise NotFound unless @stop
  end

#  def search(q, only = "id,name,location")
#    only_provides :json
#
#    @stops = Stop.search :conditions => [q]
#    render @stops, :only => only.split(",").map{|x| x.to_sym}, :methods => [:print_nextstops]
#  end
#
#  def search_by_name(q, only = "id,name")
#    only_provides :json
#
#    @stops = Stop.all :name => q
#    display @stops #, {:only => only.split(",").map{|x| x.to_sym}, :methods => [:print_nextstops]}
#  end

  def timetables

    @stop = Stop.get(params['id'])
    raise NotFound unless @stop
    @timetables = @stop.timetables.sort_by{|x| x['line']}

    respond_with @timetables.map{ |timetable| timetable.only(* params['only'].blank? ? ["_id", "line", "line_id"] : params['only'].split(",")) }
  end

end # Stops
