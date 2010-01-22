Given /^(only )?line with (.+) exists$/ do |only, params|                                                                                                                                         
  Given "there are no lines" if only
  @line = Line.new
  @line.begin_date = Date.today
  params.scan(/(\S+) "(\S+)"/) do |name, value|
    @line.send("#{name}=", value)
  end
  @line.save
end

Given /^(only )?line "(.+)" exists$/ do |only, no|
  Given "#{only ? "only " : ""}line with no \"#{no}\" exists"
end

Given "there are no lines" do
  Line.all.destroy!
end

Given /^the following lines exist in the system:$/ do | attrs_table |
  Given "there are no lines"
  attrs_table.hashes.each do |attrs|
    line = Line.new attrs
    line.save
  end
end

Then /^I should see "([^\"]*)" lines numbers$/ do |count|
  @response.should have_selector("#linesIndex > .zebra", :count => count.to_i)
end

Then /^I should see "([^\"]*)" links to line show page$/ do |count|
  @response.should have_selector("#linesIndex > .zebra > .td > .zebra2 > a[href^='/lines/']", :count => count.to_i)
end

Then /^I should see statistics$/ do
  @response.should have_selector("#objDetails")
end

Then /^I should (not )?see link to line's timetables$/ do |yn|
  if yn
    @response.should_not have_selector("a", :content => 'Pokaż przystanki na trasie')
  else
    @response.should have_selector("a", :content => 'Pokaż przystanki na trasie')
  end
end

Then /^I should (not )?see link to opposite line$/ do |yn|
  if yn
    @response.should_not have_selector("a[href^='/lines/']", :content => 'Pokaż przeciwną linię')
  else
    @response.should have_selector("a[href^='/lines/']", :content => 'Pokaż przeciwną linię')
  end
end

Then /^I should (not )?see line's route$/ do |yn|
  if yn
    @response.should_not have_selector("#lineRoute")
  else
    @response.should have_selector("#lineRoute")
  end
end

Given /^only lines with no "([^\"]*)", beginning "([^\"]*)" and direction "([^\"]*)"$/ do |no, beginning, direction|
  Line.all.destroy!
  Stop.all.destroy!
  Timetable.all.destroy!

  line1 = Line.new(:no => no, :begin_date => "01.01.2001")
  line1.save
  stop = Stop.new(:name => beginning, :trams => true, :buses => true, :lat => 0, :lon => 0)
  stop.save
  timetable = line1.timetables.build(:stop_id => stop.id)
  timetable.getData
  timetable.save

  line = Line.new(:no => no, :begin_date => "01.01.2001")
  line.save
  stop = Stop.new(:name => direction, :trams => true, :buses => true, :lat => 0, :lon => 0)
  stop.save
  timetable = line.timetables.build(:stop_id => stop.id)
  timetable.getData
  timetable.save

  line1.save
  line.save
end

Then /^I should see line's route beginning with "([^\"]*)"$/ do |beginning|
  @response.should have_selector("#lineRoute > div:first-child > span", :content => beginning)
end
