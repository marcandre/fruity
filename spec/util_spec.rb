require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Fruity
  describe Util do
    its(:clock_precision) { should == 1.0e-6 }

    its(:proper_time_precision) { should == 4.0e-06 }

    describe :sufficient_magnitude do
      it "returns a big value for a quick (but not trivial)" do
        Util.sufficient_magnitude(->{ 2 + 2 }).should > 10000
      end

      it "return 1 for a sufficiently slow block" do
        Util.sufficient_magnitude(->{sleep(0.01)}).should == 1
      end

      it "should raise an error for a trivial block" do
        ->{
          Util.sufficient_magnitude(->{})
        }.should raise_error
      end
    end

    describe :stats do
      it "raises an error on an empty list of values" do
        ->{
          Util.stats([])
        }.should raise_error
      end

      it "returns cools stats on the given values" do
        Util.stats([0, 4]).should == {
          :min => 0,
          :max => 4,
          :mean => 2,
          :sample_std_dev => 2.8284271247461903,
        }
      end
    end
  end
end
