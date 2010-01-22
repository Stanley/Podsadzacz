require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Stop do

  context "crating new" do

    before(:all) do
      Merb::Cache[:memcached].delete_all
      Stop.auto_migrate!
      
      @days = [
        Date.parse("Mon"),
        Date.parse("Sat"),
        Date.parse("Sun")
      ]
    end

    before do
      @stop = Stop.new :name => "Przystanek", :lat => 20.12345, :lng => 50.01234, :location => "Sezamkowa"
      @stop.save
    end

    after do
      @stop.destroy
    end

    it "should be valid" do
      @stop.should be_valid
    end

    it "should be indexed in sphinxsearch" do
      system('indexer stops --rotate')
      Stop.search(:conditions => [@stop.name]).should include(@stop)
      Stop.search(:conditions => [@stop.location]).should include(@stop)
    end

    it "should not be active" do
      @stop.active?.should be_false
    end

    it "should be active if accepts trams" do
      @stop.trams = true
      @stop.active?.should be_true
    end

    it "should be active if accepts busess" do
      @stop.buses = true
      @stop.active?.should be_true
    end

    it "should generate no traffic" do
      @days.each do |day|
        @stop.vph(day).should == 0
      end
    end

    it "should have range zero" do
      @stop.range.should == 0
    end

    it "shouldn't have opposite stop" do
      @stop.opposite.should be_empty
    end

    it "shouldn't have departures" do
      @stop.departures.should be_empty
    end

    it "shouldn't have nextstops" do
      @stop.nextstops.should be_empty
    end

    it "shouldn't have prevstops" do
      @stop.prevstops.should be_empty
    end

    it "shoud have no surroinding" do
      @stop.surrounding.should eql("brak → Przystanek → brak")
    end

    it "should belong to a hub" do
      @stop.hub.should equal(Hub.get("Przystanek"))
    end

    it "should have a hub, which contains only one stop" do
      @stop.hub.should have(1).all
    end

    it "should not have gcharts" do
      @days.each do |day|
        @stop.gchart(day).should eql({})
      end
    end

  end
end
# 
# describe "New active" do
# 
#   it "should generate some traffic"
# 
#   it "should have a range"
# 
#   it "should have few departures"
# 
#   it "should have some nextstops"
# 
#   it "should have some prevstops"
# 
#   describe "bus stop" do
# 
#     it "should generate some traffic"
# 
#     it "should have a range"
# 
#     it "should have few departures"
# 
#     it "should have some nextstops"
# 
#     it "should have some prevstops"
# 
#   end
# 
#   describe "tram stop" do
# 
#     it "should generate some traffic"
# 
#     it "should have a range"
# 
#     it "should have few departures"
# 
#     it "should have some nextstops"
# 
#     it "should have some prevstops"
# 
#   end
# end