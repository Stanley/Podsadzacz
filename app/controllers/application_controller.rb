class ApplicationController < ActionController::Base
  protect_from_forgery

  layout proc{ |controller| controller.request.xhr? ? 'xhr' : "application" }
end
