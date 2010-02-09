class MapController < ApplicationController


  def index

    if request.xhr?
      render :layout => false
    end
  end
end
