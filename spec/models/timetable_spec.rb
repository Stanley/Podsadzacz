require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Timetable do

  context "creating invalid new" do

    before(:all) do
      Merb::Cache[:memcached].delete_all
      Timetable.auto_migrate!
    end

    before do
      @timetable = Timetable.new
    end

    after do
      @timetable.destroy
    end

    it "should not be valid" do
      @timetable.should_not be_valid
      @timetable.errors.on(:line_id).should_not be_empty
      @timetable.errors.on(:stop_id).should_not be_empty
    end

    it "should be missing data" do
      @timetable.line_id = 1
      @timetable.stop_id = 1
      @timetable.should_not be_valid
    end

  end

  shared_examples_for "valid" do

    it "should be valid" do
      @timetable.should be_valid
    end

  end

  context "creating valid new" do

    before(:all) do
      Merb::Cache[:memcached].delete_all
      Timetable.auto_migrate!
      Line.auto_migrate!
      Line.create :id => 1, :no => 0, :begin_date => Date.parse("Mon")
    end

    before do # 4[BRONOWICE MAŁE]: Struga
      @timetable = Timetable.new :stop_id => 1, :line_id => 1, :start => 4

      @timetable.table1 = [28, 20, 15, 18, 9, 7, 10, 10, 10, 10, 10, 10, 10, 9, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,10, 10, 10, 10, 10, 10, 10, 10, 11, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 9, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 11, 20, 20, 20, 20, 20, 20, 20, 20, 20]
      @timetable.table2 = [20, 20, 20, 20, 20, 20, 19, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 30, nil, 30, 30, 30, 31, 31, 29, nil, nil]
      @timetable.table3 = [57, 30, 30, 30, 30, 20, 24, 20, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 30, nil, 30, 30, 30, 31, 31, 29, nil, nil]
      @timetable.save
    end

    after do
      @timetable.destroy
    end

    it_should_behave_like "valid"

    it "should return minutes sum" do
      @timetable.minutes_sum(Date.parse("Nov 30 2009"), 0).should eql(28 + @timetable.start*60)
      @timetable.minutes_sum(Date.parse("Nov 30 2009"), 1).should eql(48 + @timetable.start*60)
      
      @timetable.minutes_sum(Date.parse("Nov 28 2009"), 10).should eql(219 + @timetable.start*60)
      
      @timetable.minutes_sum(Date.parse("Nov 29 2009"), 51).should eql(1130 + @timetable.start*60)
    end

    it "should have nextruns" do
      # Weekdays
      @timetable.nextruns(DateTime.parse("Nov 30 2009 20:30"), 1).should eql([17])
      @timetable.nextruns(DateTime.parse("Dec 2 2009 12:00"), 3).should eql([6, 16, 26])
      @timetable.nextruns(DateTime.parse("Dec 3 2009 18:56"), 3).should eql([0, 10, 20])
      @timetable.nextruns(DateTime.parse("Dec 3 2009 15:00")).should eql([7, 17, 27, 37, 47, 57])
      @timetable.nextruns(DateTime.parse("Dec 3 2009 15:07")).should eql([0, 10, 20, 30, 40, 50])
      # Sutarday
      @timetable.nextruns(DateTime.parse("Nov 28 2009 3:30"), 2).should eql([50])
      @timetable.nextruns(DateTime.parse("Nov 21 2009 22:01"), 2).should eql([20, 49])
      @timetable.nextruns(DateTime.parse("Nov 28 2009 14:38"), 6).should eql([1, 21, 41])
      @timetable.nextruns(DateTime.parse("Nov 21 2009 11:00")).should eql([19, 39, 59])
      # Sunday
      @timetable.nextruns(DateTime.parse("Nov 29 2009 22:50"), 1).should eql([0])
      @timetable.nextruns(DateTime.parse("Dec 20 2009 18:09"), 3).should eql([10, 30, 50])
      @timetable.nextruns(DateTime.parse("Nov 29 2009 12:10")).should eql([9, 29, 49])
    end

    it "should not have nextruns when too late" do
      # Weekdays
      @timetable.nextruns(DateTime.parse("Nov 30 2009 2:30"), 1).should eql([])
      @timetable.nextruns(DateTime.parse("Dec 3 2009 22:48"), 3).should eql([])
      # Sutarday
      @timetable.nextruns(DateTime.parse("Nov 21 2009 3:10"), 2).should eql([])
      # Sunday
      @timetable.nextruns(DateTime.parse("Nov 29 2009 22:51"), 1).should eql([])
    end

    it "should not have any special runs" do
      pending
    end

    it "should return last run time" do
      @timetable.last(Date.parse("Nov 30 2009")).should eql(Time.parse("Nov 30 2009 22:47"))
      @timetable.last(Date.parse("Nov 22 2009")).should eql(Time.parse("Nov 22 2009 22:50"))
    end

    it "should return time when given absolute run number" do
      @timetable.absolute_arrival(Date.parse("Nov 30 2009"), 0).should eql(Time.parse("Nov 30 2009 4:28"))
      @timetable.absolute_arrival(Date.parse("Nov 23 2009"), 7).should eql(Time.parse("Nov 23 2009 5:57"))

      @timetable.absolute_arrival(Date.parse("Nov 28 2009"), 0).should eql(Time.parse("Nov 28 2009 4:20"))
      @timetable.absolute_arrival(Date.parse("Nov 21 2009"), 10).should eql(Time.parse("Nov 21 2009 7:39"))

      @timetable.absolute_arrival(Date.parse("Nov 29 2009"), 0).should eql(Time.parse("Nov 29 2009 4:57"))
      @timetable.absolute_arrival(Date.parse("Nov 22 2009"), 49).should eql(Time.parse("Nov 22 2009 22:50"))
    end

    it "should raise error when given wrong run number" do
      lambda { @timetable.arrival(Date.parse("Nov 30 2009"), 100) }.should raise_error
      lambda { @timetable.arrival(Date.parse("Nov 21 2009"), -70) }.should raise_error
      lambda { @timetable.arrival(Date.parse("Nov 22 2009"), 57) }.should raise_error
    end

    it "should return valid run number" do
      @timetable.run_number(Time.parse("Nov 30 2009 4:28")).should equal(0)
      @timetable.run_number(Time.parse("Nov 30 2009 6:27")).should equal(10)

      @timetable.run_number(Time.parse("Nov 28 2009 8:59")).should equal(14) # sobota

      @timetable.run_number(Time.parse("Nov 29 2009 5:57")).should equal(2)
    end

    it "should raise an error when wrong argument given to run number" do
      lambda { @timetable.run_number(Time.parse("Nov 30 2009 6:40"))  }.should raise_error(ArgumentError)
      lambda { @timetable.run_number(Time.parse("Nov 28 2009 16:05")) }.should raise_error(ArgumentError)
      lambda { @timetable.run_number(Time.parse("Nov 29 2009 23:13")) }.should raise_error(ArgumentError)
    end

    it "should iterate" do
      i = 0
      @timetable.each do
        i += 1
      end
      
      i.should eql(3)
    
    end

  end

  context "creating valid new with description" do


    before(:all) do
      Merb::Cache[:memcached].delete_all
      Timetable.auto_migrate!
      Line.auto_migrate!
      Line.create :id => 1, :no => 0, :begin_date => Date.parse("Mon")
    end

    before do # 16[WALCOWNIA]: Dunikowskiego
      @timetable = Timetable.new :stop_id => 0, :line_id => 1, :start => 4

      @timetable.table1 = [56, 10, 10, 9, 11, 10, 9, 11, 10, 12, 9, 12, 8, 10, 10, 20, 10, 10, 11, 15, 10, 15, 10, 10, 20, 20, 20, 20, 20, 20, 20, 20, 20, 19, 20, 11, 10, 10, 10, 13, 15, 10, 10, 10, 10, 14, 13, 13, 12, 8, 10, 10, 20, 12, 10, 10, 16, 7, 14, 20, 20, 15, 20, 20, 20, 25, 15, 21, 20, 11, 9, 20, 21, 20, 19, 19, 28] 
      @timetable.table2 = [71, 25, 19, 20, 20, 20, 22, 36, 20, 20, 20, 28, 32, 20, 20, 20, 20, 27, 33, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 22, 38, 20, 20, 20, 20, 20, 40, 20, 20, 20, 20, 30, 31, 30, 30, 30, 30] 
      @timetable.table3 = [67, 27, 30, 30, 30, 30, 31, 28, 20, 21, 39, 20, 20, 20, 20, 27, 33, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 22, 38, 20, 20, 20, 20, 20, 35, 25, 20, 20, 20, 30, 31, 30, 30, 30, 30]
      @timetable.save
    end

    after do
      @timetable.destroy
    end

    it_should_behave_like "valid"

    it "should have special runs" do
      @timetable.minutes(Time.parse("Nov 30 2009 0:00")).should have(77).items
      @timetable.minutes(Time.parse("Nov 21 2009 12:00")).should have(47).items
      @timetable.minutes(Time.parse("Nov 29 2009 23:59")).should have(45).items
    end

    it "should return valid run number" do
      @timetable.run_number(Time.parse("Nov 30 2009 6:37")).should equal(10)
      @timetable.run_number(Time.parse("Nov 28 2009 16:33")).should equal(30)
      @timetable.run_number(Time.parse("Nov 29 2009 21:14")).should equal(40)
    end

    it "should raise an error when wrong argument given to run number" do
      lambda { @timetable.run_number(Time.parse("Nov 30 2009 6:40"))  }.should raise_error(ArgumentError)
      lambda { @timetable.run_number(Time.parse("Nov 28 2009 16:05")) }.should raise_error(ArgumentError)
      lambda { @timetable.run_number(Time.parse("Nov 29 2009 23:13")) }.should raise_error(ArgumentError)
    end
  end
end