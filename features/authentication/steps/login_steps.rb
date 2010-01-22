Given /^I am not authenticated$/ do
  # yay!
end

Given /^I am authenticated$/ do
  User.all.destroy!
  user = User.create(:login => "the_login",  
    :password => "password",  
    :password_confirmation => "password")
  visit "/login"  
  fill_in("login", :with => "the_login")  
  fill_in("password", :with => "password")  
  click_button("Log in")
end