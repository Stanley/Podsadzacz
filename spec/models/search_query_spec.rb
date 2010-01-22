require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe SearchQuery do

  it "should have specs"

end

describe Node do

  it "should be root" do
     Node.new.children.should be_empty
  end

  it "should have parent" do
    root = Node.new
    child = Node.new(root)

    child.parent.should eql(root)
  end

  it "should have tail" do
    root = Node.new

    child1 = Node.new(root, [1,2,3])
    child2 = Node.new(root, [4,5,6])

    grandchild1 = Node.new(child1, [7,8,9])
    grandchild2 = Node.new(child1, [10,11,12])
    grandchild3 = Node.new(child2, [13,14,15])

    greatgrandchild = Node.new(grandchild2, [100])

    greatgrandchild.tail.should eql([[100], [10, 11, 12], [1,2,3]])
  end

end