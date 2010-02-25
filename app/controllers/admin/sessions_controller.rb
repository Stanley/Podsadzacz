class Admin::SessionsController < ActionController::Base
  before_filter :authenticate_admin!, :only => [:show]
end