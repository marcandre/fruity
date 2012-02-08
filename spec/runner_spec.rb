require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Fruity
  describe Runner do
    let(:group) { Group.new(:upcase, :downcase, :on => "Hello") }
    let(:runner){ Runner.new(group) }

    it "runs from a Group" do
      run = runner.run(:samples => 42, :magnify => 100)
      run.timings.should be_array_of_size(2, 42)
      run.baselines.should be_array_of_size(2, 42)
    end

    it "can use a single baseline" do
      run = runner.run(:samples => 42, :magnify => 100, :baseline => :single)
      run.timings.should be_array_of_size(2, 42)
      run.baselines.should be_array_of_size(42)
    end

    it "can use no baseline" do
      run = runner.run(:samples => 42, :magnify => 100, :baseline => :none)
      run.timings.should be_array_of_size(2, 42)
      run.baselines.should == nil
    end
  end
end