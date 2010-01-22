After do
  @cleanup_types.each { |klass| klass.all.destroy! }
end
 
Before do
  @cleanup_types = []
end

Given /^(only )?stop with (.+) exists$/ do |only, params|                                                                                                                                         
  Given "there are no stops" if only
 
  @stop = Stop.new
  params.scan(/(\S+) "(\S+)"/) do |name, value|
    @stop.send("#{name}=", value)
  end
  @stop.save
end

Given /^(only )?stop "(.+)" exists$/ do |only, name|
  Given "#{only ? "only " : ""}stop with name \"#{name}\" exists"
end

Given "there are no stops" do
  Stop.all.destroy!
end

Given /^the following stops exist in the system:$/ do | attrs_table |
  Stop.all.destroy!

  attrs_table.hashes.each do |attrs|
    stop = Stop.new attrs
    stop.save
  end
end

Then /^I should not see any stops$/ do
  @response.should_not have_selector("#stopsIndex div")
end

Then /^I should see "([^\"]*)" link highlighted$/ do |category|
  @response.should have_selector(".actived:contains("+category+")")
end

Then /^I should see (.*) links to "([^\"]*)"$/ do |i, what|
  @response.should have_selector("a[href^='/" + what + "/']", :count => i.to_i)
end

Given /^timetable for given stop and line$/ do
  t = @line.timetables.build(:stop_id => @stop.id)
  t.getData
  t.save
  @line.save
end

Then /^I should see (.+) links to "([^\"]*)" as "([^\"]*)"$/ do |i, dest, link|
  @response.should have_selector("a[href^='"+dest+"']:contains('"+link+"')", :count => i.to_i)
end

Then /^I should see "([^\"]*)" link$/ do |link|
  @response.should have_selector("a:contains('"+link+"')")
end

Then /^I should see next departures for line "([^\"]*)"$/ do |link|
  @response.should have_selector("a[href^='/timetables/']:contains('"+link+"')")
end

Then /^I should see (non\-)?zero stats$/ do |non|
  pending
end

Given /^(.*) opposite stop/ do |i|
  i.to_i.times do
    @opposite = Stop.new(:name => @stop.name, :location => @stop.location, :lat => @stop.lat, :lng => @stop.lng)
    @opposite.save
  end
end