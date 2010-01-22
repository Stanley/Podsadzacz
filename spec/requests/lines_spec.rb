require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a line exists" do
  Line.all.destroy!
  request(resource(:lines), :method => "POST", 
    :params => { :line => { :id => nil }})
end

describe "resource(:lines)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:lines))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of lines" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a line exists" do
    before(:each) do
      @response = request(resource(:lines))
    end
    
    it "has a list of lines" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Line.all.destroy!
      @response = request(resource(:lines), :method => "POST", 
        :params => { :line => { :id => nil }})
    end
    
    it "redirects to resource(:lines)" do
      @response.should redirect_to(resource(Line.first), :message => {:notice => "line was successfully created"})
    end
    
  end
end

describe "resource(@line)" do 
  describe "a successful DELETE", :given => "a line exists" do
     before(:each) do
       @response = request(resource(Line.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:lines))
     end

   end
end

describe "resource(:lines, :new)" do
  before(:each) do
    @response = request(resource(:lines, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@line, :edit)", :given => "a line exists" do
  before(:each) do
    @response = request(resource(Line.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@line)", :given => "a line exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Line.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @line = Line.first
      @response = request(resource(@line), :method => "PUT", 
        :params => { :line => {:id => @line.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@line))
    end
  end
  
end

