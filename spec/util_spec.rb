require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Fruity
  describe Util do
    its(:clock_precision) { should == 1.0e-6 }

    its(:proper_time_precision) { should == 4.0e-06 }

    describe :sufficient_magnification do
      it "returns a big value for a quick (but not trivial)" do
        Util.sufficient_magnification(->{ 2 + 2 }).should > 10000
      end

      it "return 1 for a sufficiently slow block" do
        Util.sufficient_magnification(->{sleep(0.01)}).should == 1
      end

      it "should raise an error for a trivial block" do
        ->{
          Util.sufficient_magnification(->{})
        }.should raise_error
      end
    end

    describe :stats do
      it "returns cools stats on the given values" do
        Util.stats([0, 4]).should == {
          :min => 0,
          :max => 4,
          :mean => 2,
          :sample_std_dev => 2.8284271247461903,
        }
      end
    end

    describe :difference do
      it "returns stats for the difference of two series" do
        s = Util.stats([0, 4])
        Util.difference(s, s).should == {
          :min => -4,
          :max => 4,
          :mean => 0,
          :sample_std_dev => 4,
        }
      end

      it "gives similar results when comparing an exec and its baseline from stats on proper_time" do
        exec = ->{ 2 ** 3 ** 4 }
        options = {:magnify => Util.sufficient_magnification(exec) }
        n = 100
        timings  = [exec, ->{}].map do |e|
          n.times.map { Util.real_time(e, options) }
        end
        proper = Util.stats(timings.transpose.map{|e, b| e - b})
        diff = Util.difference(*timings)
        diff[:mean].should   be_within(Float::EPSILON).of(proper[:mean])
        diff[:max].should    be_between(proper[:max], proper[:max]*2)
        diff[:min].should    <= proper[:min]
        diff[:sample_std_dev].should be_between(proper[:sample_std_dev], 2 * proper[:sample_std_dev])
      end
    end

    describe :filter do
      it "returns the filtered series" do
        Util.filter([4, 5, 2, 3, 1], 0.21, 0.39).should == [2, 3, 4]
      end
    end
  end
end
