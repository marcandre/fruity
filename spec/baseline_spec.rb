require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Fruity
  describe Baseline do
    describe "#[]" do
      it "returns an object of the right type" do
        b = Baseline[Proc.new{ 42 }]
        b.class.should == Proc
        b.lambda?.should == false
        b.call.should == nil

        b = Baseline[lambda{ 42 }]
        b.class.should == Proc
        b.lambda?.should == true
        b.call.should == nil

        b = Baseline[Fruity.method(:compare)]
        b.class.should == Method
        b.call.should == nil
      end

      it "copies the arity" do
        b = Baseline[lambda{|a, b| 42}]
        b.call(1, 2).should == nil
        lambda{
          b.call(1)
        }.should raise_error
        lambda{
          b.call(1, 2, 3)
        }.should raise_error
        
        Baseline[lambda{|a, *b| 42}].call(1, 2, 3, 4, 5, 6).should == nil
      end
    end
  end
end