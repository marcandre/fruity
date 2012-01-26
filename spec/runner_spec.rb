require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Fruity
  describe Runner do
    it "runs from a Group" do
      group = Group.new(:upcase, :downcase, :on => "Hello")
      runner = Runner.new(group)
      run = runner.run(:samples => 42)
      run.should be_instance_of ComparisonRun
      run.size.should == 42
    end
  end
end