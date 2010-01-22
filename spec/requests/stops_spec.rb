require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a stop exists" do
  Stop.all.destroy!
  request(resource(:stops), :method => "POST", 
    :params => { :stop => { :id => nil }})
end

describe "resource(:stops)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:stops))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of stops" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a stop exists" do
    before(:each) do
      @response = request(resource(:stops))
    end
    
    it "has a list of stops" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Stop.all.destroy!
      @response = request(resource(:stops), :method => "POST", 
        :params => { :stop => { :id => nil }})
    end
    
    it "redirects to resource(:stops)" do
      @response.should redirect_to(resource(Stop.first), :message => {:notice => "stop was successfully created"})
    end
    
  end
end

describe "resource(@stop)" do 
  describe "a successful DELETE", :given => "a stop exists" do
     before(:each) do
       @response = request(resource(Stop.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:stops))
     end

   end
end

describe "resource(:stops, :new)" do
  before(:each) do
    @response = request(resource(:stops, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@stop, :edit)", :given => "a stop exists" do
  before(:each) do
    @response = request(resource(Stop.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@stop)", :given => "a stop exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Stop.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @stop = Stop.first
      @response = request(resource(@stop), :method => "PUT", 
        :params => { :stop => {:id => @stop.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@stop))
    end
  end
  
end

