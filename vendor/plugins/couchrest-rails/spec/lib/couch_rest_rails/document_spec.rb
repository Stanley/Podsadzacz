require File.dirname(__FILE__) + '/../../spec_helper'

describe CouchRestRails::Document do
  
  test_class = class CouchRestRailsTestDocument < CouchRestRails::Document 
    use_database :foo
    
    self
  end
  
  before :each do
    @doc = test_class.new
  end
  
  it "should inherit from CouchRest::ExtendedDocument" do
    CouchRestRails::Document.ancestors.include?(CouchRest::ExtendedDocument).should be_true
  end
  
  it "should define its CouchDB connection and CouchDB database name" do
    @doc.database.name.should == "#{COUCHDB_CONFIG[:db_prefix]}foo#{COUCHDB_CONFIG[:db_suffix]}"
  end

  describe '.unadorned_database_name' do
    
    it "should return the database name without the prefix and suffix" do
      test_class.unadorned_database_name.should == 'foo'
    end
    
  end

  it "should return only those properties we are asking for" do
    article = Article.create(:title => 'my title', :content => 'my content')
    article.only("title").should == {'title' => 'my title', 'couchrest-type' => 'Article'}
    article.except("title").delete("title").should be_nil
  end

end
