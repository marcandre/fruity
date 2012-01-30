require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Fruity
  describe ComparisonRun do
    let(:group)  { Group.new ->{1}, ->{2} }
    let(:timings){ ([[1.0, 2.0]] * 10).transpose }
    subject      { @run = ComparisonRun.new(group, timings, nil) }

    its(:comparison) { should == {
        :mean=>2.0,
        :factor=>2.0,
        :max=>2.0,
        :min=>2.0,
        :rounding=>666,
        :precision=>0.0,
      }
    }
  
  end
end