require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a timetable exists" do
  Timetable.all.destroy!
  request(resource(:timetables), :method => "POST", 
    :params => { :timetable => { :id => nil }})
end

describe "resource(:timetables)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:timetables))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of timetables" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a timetable exists" do
    before(:each) do
      @response = request(resource(:timetables))
    end
    
    it "has a list of timetables" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Timetable.all.destroy!
      @response = request(resource(:timetables), :method => "POST", 
        :params => { :timetable => { :id => nil }})
    end
    
    it "redirects to resource(:timetables)" do
      @response.should redirect_to(resource(Timetable.first), :message => {:notice => "timetable was successfully created"})
    end
    
  end
end

describe "resource(@timetable)" do 
  describe "a successful DELETE", :given => "a timetable exists" do
     before(:each) do
       @response = request(resource(Timetable.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:timetables))
     end

   end
end

describe "resource(:timetables, :new)" do
  before(:each) do
    @response = request(resource(:timetables, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@timetable, :edit)", :given => "a timetable exists" do
  before(:each) do
    @response = request(resource(Timetable.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@timetable)", :given => "a timetable exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Timetable.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @timetable = Timetable.first
      @response = request(resource(@timetable), :method => "PUT", 
        :params => { :timetable => {:id => @timetable.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@timetable))
    end
  end
  
end

