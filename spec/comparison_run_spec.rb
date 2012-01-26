require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Fruity
  describe ComparisonRun do
    let(:group)  { Group.new ->{1}, ->{2} }
    let(:timings){ ([[1.0, 2.0]] * 10).transpose }
    subject      { @run = ComparisonRun.new(group, timings) }

    describe :comparison do
      its(:comparison) { should == {
          :mean=>2.0,
          :factor=>2.0,
          :max=>2.000012000048,
          :min=>1.9999880000480001,
          :rounding=>4.920818753952375,
          :precision=>1.0e-05,
        }
      }
    end
  
  end
end