require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a polyline exists" do
  Polyline.all.destroy!
  request(resource(:polylines), :method => "POST", 
    :params => { :polyline => { :id => nil }})
end

describe "resource(:polylines)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:polylines))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of polylines" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a polyline exists" do
    before(:each) do
      @response = request(resource(:polylines))
    end
    
    it "has a list of polylines" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Polyline.all.destroy!
      @response = request(resource(:polylines), :method => "POST", 
        :params => { :polyline => { :id => nil }})
    end
    
    it "redirects to resource(:polylines)" do
      @response.should redirect_to(resource(Polyline.first), :message => {:notice => "polyline was successfully created"})
    end
    
  end
end

describe "resource(@polyline)" do 
  describe "a successful DELETE", :given => "a polyline exists" do
     before(:each) do
       @response = request(resource(Polyline.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:polylines))
     end

   end
end

describe "resource(:polylines, :new)" do
  before(:each) do
    @response = request(resource(:polylines, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@polyline, :edit)", :given => "a polyline exists" do
  before(:each) do
    @response = request(resource(Polyline.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@polyline)", :given => "a polyline exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Polyline.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @polyline = Polyline.first
      @response = request(resource(@polyline), :method => "PUT", 
        :params => { :polyline => {:id => @polyline.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@polyline))
    end
  end
  
end

