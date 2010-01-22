require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require 'merb/mpk/lib/mpk'

DAYS = {
  :monday => Date.parse("Mon"),
  :saturday => Date.parse("Sat"),
  :sunday => Date.parse("Sun")
}

describe Line do

  describe "new" do

    #before(:all) do
    #  Merb::Cache[:memcached].delete_all
    #  Line.auto_migrate!
    #end

    before do
      @line = Line.new :no => 14, :begin_date => Date.today
      @line.save
    end

    after do
      @line.destroy
    end

    it "should be valud" do
      @line.should be_valid
    end

    it "should have length equal zero" do
      @line.length.should == 0
    end

    it "should not have opposite line" do
      @line.opposite.should be_nil
    end

    it "should have no runs" do
      @line.runs(DAYS[:monday]).should eql(0)
      @line.runs(DAYS[:saturday]).should eql(0)
      @line.runs(DAYS[:sunday]).should eql(0)
    end

    it "should have speed of zero" do
      @line.avg_time(DAYS[:monday]).should == 0
      @line.avg_time(DAYS[:saturday]).should == 0
      @line.avg_time(DAYS[:sunday]).should == 0
    end
  end

  describe "when adding 3rd line with the same number" do

    before do
      2.times{ Line.create :no => 14, :begin_date => Date.today }
    end

    after do
      Line.auto_migrate!
    end
    
    it "should not be valid" do
      @line = Line.create :no => 14, :begin_date => Date.today
      @line.should_not be_valid
    end
  end


  shared_examples_for "complete" do

    it "should have the same numbers of runs (including nils) on it's every stop" do
      #p @line.timetables.map{|x| x.minutes(DAYS[:saturday]).size}
      @line.timetables.map{|x| x.minutes(DAYS[:monday]).size}.select{|x| x > 0}.uniq.should have(1).item if @line.runs?(DAYS[:monday])
      @line.timetables.map{|x| x.minutes(DAYS[:saturday]).size}.select{|x| x > 0}.uniq.should have(1).item if @line.runs?(DAYS[:saturday])
      @line.timetables.map{|x| x.minutes(DAYS[:sunday]).size}.select{|x| x > 0}.uniq.should have(1).item if @line.runs?(DAYS[:sunday])
    end

    it "should have no more runs than the biggest timetable" do
      DAYS.each do |_,d|
        max = @line.timetables.map{|x| x.runs(d)}.max
        @line.timetables.map{|x| x.minutes(d).size}.max.should eql(max)
      end
    end

    it "should have futher time on each next stop" do
      [1, @line.timetables.size].each do |run_number|                                       # pierwszy i ostatni
        @line.timetables.each do |t|
          if t.nextinline and not ( t.minutes(DAYS[:monday])[run_number].nil? or t.nextinline.minutes(DAYS[:monday])[run_number].nil? )
            ((t.nextinline.arrival(DAYS[:monday], run_number) - t.arrival(DAYS[:monday], run_number)) / 60).should be_close(3, 3)
          end
        end
      end
    end

    describe "archiving," do

      it "should archive line" do
        line = @line.archive
        Line.get(@line.id).should be_nil
        line.repository.name.should eql(:archive)
      end

      it "should archive timetables" do
        old_timetables = @line.timetables.size
        line = @line.archive
        Timetable.all(:line_id => @line.id).should be_empty
        line.timetables.size.should eql(old_timetables)
      end
    end
  end


  #before(:all) do
  #  p "migrate"
  #  Merb::Cache[:memcached].delete_all
  #  Line.auto_migrate!
  #  Timetable.auto_migrate!
  #end

  describe "tram 1" do
    before do
      repository(:archive){
        Line.auto_migrate!
        Timetable.auto_migrate!
      }
      Line.auto_migrate!
      Timetable.auto_migrate!
    end

    describe "direction: Wzgórza" do
      before do
        stops = {0=>{0=>{1=>258,2=>896,3=>901,4=>909,5=>933,6=>363,7=>367,8=>993,9=>1010,10=>1013,11=>1037,12=>1056,13=>1290,14=>1064,15=>1067,16=>1299,17=>1302,18=>1236,19=>1247,20=>1251,21=>1245,22=>1241,23=>1259,24=>1931,25=>1932,26=>1934,27=>1967,28=>1969,29=>2192}}, 1=>{0=>{30=>2190,31=>2193,32=>1972,33=>1968,34=>1940,35=>1935,36=>1930,37=>1258,38=>1243,39=>1254,40=>1252,41=>1250,42=>1235,43=>1304,44=>1300,45=>1068,46=>1065,47=>1289,48=>1057,49=>1053,50=>1014,51=>1011,52=>992,53=>368,54=>366,55=>934,56=>907,57=>902,58=>895}}}
        @line = Line.auto_create("1", stops, "testing").last
      end
      it_should_behave_like "complete"

      it "should have timetables" do
        @line.timetables.should have(29).timetables
      end
    end

  end

#  describe "tram 51" do
#    before do
#      repository(:archive){
#        Line.auto_migrate!
#        Timetable.auto_migrate!
#      }
#      Line.auto_migrate!
#      Timetable.auto_migrate!
#    end
#
#    describe "direction: Dworzec Towarowy" do
#      before do
#        # 51: Bieżanów Nowy / Prokocim - Dworzec Towarowy
#        stops = {0=>{0=>{6=>202, 11=>207, 7=>203, 12=>208, 8=>204, 13=>209, 9=>205, 14=>210, 15=>211, 16=>399, 1=>197, 17=>301, 2=>198, 18=>286, 3=>199, 19=>287, 20=>395, 4=>200, 10=>206, 21=>397, 5=>201}, 1=>{43=>733}}, 1=>{0=>{22=>367, 33=>187, 23=>23, 34=>188, 24=>396, 35=>189, 25=>288, 36=>190, 26=>283, 37=>191, 27=>302, 38=>192, 28=>300, 39=>193, 40=>194, 29=>90, 30=>89, 41=>195, 31=>88, 42=>196, 32=>87}}}
#        @line = Line.auto_create("51", stops, "testing").first
#      end
#      it_should_behave_like "complete"
#      it "should have timetables" do
#        @line.timetables.should have(22).timetables
#      end
#      it "should have second beginning" do
#        @line.timetables.sort_by{|x| x.nice}[6].level.should eql(1)
#      end
#
#      it "should have second beginning" do
#        [13,14,15,17].each do |r|
#          @line.timetables[0..5].each{ |t| lambda{ t.arrival(DAYS[:monday], r) }.should raise_error }
#          lambda{ @line.timetables[6].arrival(DAYS[:monday], r) }.should_not raise_error
#        end
#
#      end
#    end
#  end
#
#  describe "line 103" do
#    before do
#      repository(:archive){
#        Line.auto_migrate!
#        Timetable.auto_migrate!
#      }
#      Line.auto_migrate!
#      Timetable.auto_migrate!
#    end
#
#    describe "direction: Mydlniki" do
#      before do
#        # 103: Wydział Farmacji UJ / Prokocim UJ - Mydlniki
#        stops = {0=>{0=>{6=>494, 11=>505, 22=>528, 7=>495, 12=>507, 23=>731, 8=>497, 13=>436, 24=>530, 9=>499, 14=>509, 25=>533, 15=>511, 26=>534, 16=>513, 27=>535, 1=>485, 17=>517, 28=>537, 2=>486, 18=>519, 29=>539, 30=>541, 3=>488, 19=>522, 20=>524, 4=>490, 10=>503, 21=>526, 5=>492}, 1=>{60=>501, 61=>502}}, 1=>{0=>{33=>538, 44=>514, 55=>730, 34=>536, 45=>512, 56=>493, 35=>533, 46=>510, 57=>491, 36=>531, 47=>435, 58=>489, 37=>529, 48=>508, 59=>487, 38=>527, 49=>506, 50=>504, 39=>525, 40=>523, 51=>500, 41=>520, 52=>498, 31=>542, 42=>518, 53=>496, 32=>540, 43=>516, 54=>599}, 1=>{62=>485}}}
#        @line = Line.auto_create("103", stops, "testing").first
#      end
#      it_should_behave_like "complete"
#      it "should have timetables" do
#        @line.timetables.should have(32).timetables
#      end
#      it "should have first 2 timetables optional" do
#        @line.timetables.select{|x| (0..1).include? x.nice }.each do |timetable|
#          timetable.level.should eql(1)
#        end
#      end
#    end
#
#    describe "direction: Wydział Farmacji UJ / Prokocim UJ" do
#      before do
#        # 103: Mydlniki - Wydział Farmacji UJ / Prokocim UJ
#        #stops = {0 => {0 => [[1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7], [8, 8], [9, 9], [10, 10], [11, 11], [12, 12], [13, 13], [14, 14], [15, 15], [16, 16], [17, 17], [18, 18], [19, 19], [20, 20], [21, 21], [22, 22], [23, 23], [24, 24], [25, 25], [26, 26], [27, 27], [28, 28], [29, 29], [30, 30]], 1 => [[60, 60], [61, 61]]}, 1 => {0 => [[31, 31], [32, 32], [33, 33], [34, 34], [35, 35], [36, 36], [37, 37], [38, 38], [39, 39], [40, 40], [41, 41], [42, 42], [43, 43], [44, 44], [45, 45], [46, 46], [47, 47], [48, 48], [49, 49], [50, 50], [51, 51], [52, 52], [53, 53], [54, 54], [55, 55], [56, 56], [57, 57], [58, 58], [59, 59]], 1 => [[62, 62]]}}
#        stops = {0=>{0=>{6=>494, 11=>505, 22=>528, 7=>495, 12=>507, 23=>731, 8=>497, 13=>436, 24=>530, 9=>499, 14=>509, 25=>533, 15=>511, 26=>534, 16=>513, 27=>535, 1=>485, 17=>517, 28=>537, 2=>486, 18=>519, 29=>539, 30=>541, 3=>488, 19=>522, 20=>524, 4=>490, 10=>503, 21=>526, 5=>492}, 1=>{60=>501, 61=>502}}, 1=>{0=>{33=>538, 44=>514, 55=>730, 34=>536, 45=>512, 56=>493, 35=>533, 46=>510, 57=>491, 36=>531, 47=>435, 58=>489, 37=>529, 48=>508, 59=>487, 38=>527, 49=>506, 50=>504, 39=>525, 40=>523, 51=>500, 41=>520, 52=>498, 31=>542, 42=>518, 53=>496, 32=>540, 43=>516, 54=>599}, 1=>{62=>485}}}
#        @line = Line.auto_create("103", stops, "testing").last
#        #p @line.all_timetables.map{|t| t.class==Array ? t.map{|x| x.id} : t.id}
#      end
#      it_should_behave_like "complete"
#      it "should have timetables" do
#        @line.timetables.should have(30).timetables
#      end
#      it "should have latest 1 timetable optional" do
#        @line.timetables.select{|x| x.nice == 29 }.each do |timetable|
#          timetable.level.should eql(1)
#        end
#      end
#    end
#  end
#
#  describe "line 112" do
#
#    before do
#      repository(:archive){
#        Line.auto_migrate!
#        Timetable.auto_migrate!
#      }
#
#      Line.auto_migrate!
#      Timetable.auto_migrate!
#
#    end
#
#    describe "direction: Tyniec Kamieniołom" do
#
#      before do
#        stops = {0=>{0=>{6=>723, 11=>744, 7=>724, 12=>745, 8=>727, 13=>749, 9=>728, 14=>756, 15=>753, 16=>764, 1=>736, 17=>766, 2=>738, 18=>768, 3=>747, 4=>719, 10=>742, 5=>720}, 1=>{40=>773, 41=>760, 42=>761, 43=>754}, 2=>{44=>759, 45=>762, 46=>755, 47=>763}, 3=>{51=>751, 52=>757}}, 1=>{0=>{22=>765, 33=>721, 23=>752, 34=>718, 24=>750, 35=>740, 25=>748, 36=>739, 26=>746, 37=>771, 27=>743, 38=>272, 28=>741, 39=>435, 29=>729, 30=>726, 19=>770, 20=>769, 31=>725, 21=>767, 32=>722}, 1=>{48=>772, 49=>774, 50=>758}, 2=>{53=>751, 54=>757}}}
#        @line = Line.auto_create("112", stops, "testing").first
#      end
#
#      it "should have timetables" do
#        @line.timetables.should have(28).timetables
#      end
#      it_should_behave_like "complete"
#    end
#
#    describe "direction: Rondo Grunwaldzkie" do
#      before do
#        stops = {0=>{0=>{6=>723, 11=>744, 7=>724, 12=>745, 8=>727, 13=>749, 9=>728, 14=>756, 15=>753, 16=>764, 1=>736, 17=>766, 2=>738, 18=>768, 3=>747, 4=>719, 10=>742, 5=>720}, 1=>{40=>773, 41=>760, 42=>761, 43=>754}, 2=>{44=>759, 45=>762, 46=>755, 47=>763}, 3=>{51=>751, 52=>757}}, 1=>{0=>{22=>765, 33=>721, 23=>752, 34=>718, 24=>750, 35=>740, 25=>748, 36=>739, 26=>746, 37=>771, 27=>743, 38=>272, 28=>741, 39=>435, 29=>729, 30=>726, 19=>770, 20=>769, 31=>725, 21=>767, 32=>722}, 1=>{48=>772, 49=>774, 50=>758}, 2=>{53=>751, 54=>757}}}
#        @line = Line.auto_create("112", stops, "testing").last
#      end
#      it "should have timetables" do
#        @line.timetables.should have(26).timetables
#      end
#      it_should_behave_like "complete"
#    end
#  end

#  describe "#comlpeted" do
#
#    before(:all) do
#
#
#
#
#      stops = {}
#      2.times do |i|
#        31.times do |j|
#          stops[i] ||= {}
#          stops[i][0] ||= {}
#          stops[i][0][(j+1) + 31*i] = j
#        end
#      end
#
#      Line.auto_create("4", stops, "testing")
#
#      stops = {}
#      2.times do |i|
#        15.times do |j|
#          stops[i] ||= {}
#          stops[i][0] ||= {}
#          stops[i][0][(j+1) + 15*i] = j
#        end
#      end
#
#      Line.auto_create("16", stops, "testing")
#
#    end
#
#
#    describe "new with shorter runs" do
#
#      before(:all) do
#        @line = Line.get 1
#      end
#
#      it_should_behave_like "complete"
#
#      it "should have runs" do
#
#        @line.timetables.each do |t|
#          t.minutes(DAYS[:monday]).size.should eql(100)
#        end
#
#        @line.timetables.each do |t|
#          t.minutes(DAYS[:saturday]).size.should eql(53)
#        end
#
#        @line.timetables.each do |t|
#          t.minutes(DAYS[:sunday]).size.should eql(49)
#        end
#      end
#
#      it "should return valid absolute arrival time" do
#        @line.timetables[0].absolute_arrival(DAYS[:monday], 2).should eql(Time.parse( DAYS[:monday].to_s + " 5:25"))
#        @line.timetables[10].absolute_arrival(DAYS[:monday], 2).should eql(Time.parse( DAYS[:monday].to_s + " 5:09"))
#        @line.timetables[-1].absolute_arrival(DAYS[:monday], 0).should eql(Time.parse( DAYS[:monday].to_s + " 5:06"))
#      end
#
#      it "should return arrival within timetables" do
#        @line.timetables[5].arrival(DAYS[:monday], 2).should eql(Time.parse( DAYS[:monday].to_s + " 4:58"))
#        @line.timetables[6].arrival(DAYS[:monday], 0).should eql(Time.parse( DAYS[:monday].to_s + " 4:25"))
#        @line.timetables[-1].arrival(DAYS[:monday], 2).should eql(Time.parse( DAYS[:monday].to_s + " 5:41"))
#        @line.timetables[0].arrival(DAYS[:monday], -12).should eql(Time.parse( DAYS[:monday].to_s + " 19:14"))
#
##         @line.timetables[-1].absolute_arrival(DAYS[:sunday], 0).should eql(Time.parse DAYS[:sunday].to_s + " 5:34")
#      end
#
#      it "should raise an error when asking for not existing arrival within timetables" do
#        lambda { @line.timetables[0].arrival(DAYS[:monday], 0) }.should raise_error
#        lambda { @line.timetables[5].arrival(DAYS[:monday], 1) }.should raise_error
#      end
#
#    end
#
#    describe "new with special runs" do
#
#      before(:all) do
#        @line = Line.get 2
#      end
#
#      it_should_behave_like "complete"
#
#      it "should have timetables" do
#        @line.timetables.size.should eql(31)
#      end
#
#      it "should have runs" do
#
#        @line.timetables.each do |t|
#          t.minutes(DAYS[:monday]).size.should eql(100)
#        end
#
#        @line.timetables.each do |t|
#          t.minutes(DAYS[:saturday]).size.should eql(53)
#        end
#
#        @line.timetables.each do |t|
#          t.minutes(DAYS[:sunday]).size.should eql(49)
#        end
#
#      end
#
#      it "should return valid absolute_arrival time" do
#
#        @line.timetables[0].absolute_arrival(DAYS[:monday], 2).should eql(Time.parse( DAYS[:monday].to_s + " 5:10"))
#        @line.timetables[-1].absolute_arrival(DAYS[:monday], -1).should eql(Time.parse( DAYS[:monday].to_s + " 23:15"))
#
#        @line.timetables[-1].absolute_arrival(DAYS[:sunday], 0).should eql(Time.parse( DAYS[:sunday].to_s + " 5:34"))
#      end
#
#      it "should raise an error when asking for not existing arrival within timetables" do
#        lambda { @line.timetables[-1].arrival(DAYS[:monday], 105) }.should raise_error
#        lambda { @line.timetables[-6].arrival(DAYS[:sunday], -1) }.should raise_error
#      end
#
#    end
#
#    describe "another tricky line" do
#
#      before(:all) do
#        @line = Line.get 4
#      end
#
#      it_should_behave_like "complete"
#
#    end
#  end
end