require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/map" do
  before(:each) do
    @response = request("/map")
  end
end