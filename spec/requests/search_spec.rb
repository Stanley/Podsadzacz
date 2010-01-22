require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/search" do
  describe "GET" do
    before(:each) do
      @response = request("/search")
    end
    it "powinno się wyświetlać" do
      @response.should be_successful
    end

    it "powinno zawierać formularz" do
      @response.should have_selector("form[action='/search'][method='post']")
      @response.should have_selector("input[name='submit'][type='submit']")
    end

    it "powinno zawierać pola od, do" do
      @response.should have_selector("input[name='from'][type='text']")
      @response.should have_selector("input[name='to'][type='text']")
    end
  end

  describe "POST" do
    before(:each) do
      @response = request("/search", :method => "POST")
    end
    it "powinno się wyświetlać" do
      @response.should be_successful
    end

    it "powinnien być wynik zapytania" do
      pending
    end
  end
end