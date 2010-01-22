require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/current" do
  before(:each) do
    @response = request("/current")
  end
end