require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Fruity do
  it "is able to report that two identical blocks are identical" do
    report = Fruity.report(->{ 2 ** 2 }, ->{ 2 ** 2 })
    report.factor.should == 1.0
  end

  it "is able to report very small performance differences" do
    report = Fruity.report(->{ sleep(1.0) }, ->{ sleep(1.001) })
    report.factor.should == 1.001
  end

  it "is able to report a 2x difference even for small blocks" do
    report = Fruity.report(->{ 2 ** 2 }, ->{ 2 ** 2 ; 2 ** 2 })
    report.factor.should == 2.0
  end
end
