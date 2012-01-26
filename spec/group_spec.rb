require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

TOP_LEVEL = self
def foo; end
def bar; end

module Fruity
  describe Group do
    lambdas = [->{1},->{2}]

    it "can be built from lambdas" do
      group = Group.new(*lambdas)
      group.elements.values.should == lambdas
    end

    it "can be built from a block with no parameter" do
      group = Group.new do
        first(&lambdas.first)
        last(&lambdas.last)
      end
      group.elements.should == {
        :first => lambdas.first,
        :last  => lambdas.last,
      }
      group.options[:self].object_id.should equal(self.object_id)
    end

    it "can be built from a block taking a parameter" do
      group = Group.new do |cmp|
        cmp.first(&lambdas.first)
        cmp.last(&lambdas.last)
        ->{ second{} }.should raise_error(NameError)
      end
      group.elements.should == {
        :first => lambdas.first,
        :last  => lambdas.last,
      }
      group.options[:self].should == nil
    end

    it "can be built from list of method names and an object" do
      str = "Hello"
      group = Group.new(:upcase, :downcase, :on => str)
      group.elements.should == {
        :upcase => str.method(:upcase),
        :downcase => str.method(:downcase),
      }
    end

    it "can be built from list of method names and an object" do
      group = Group.new(:foo, :bar)
      group.elements.should == {
        :foo => TOP_LEVEL.method(:foo),
        :bar => TOP_LEVEL.method(:bar),
      }
    end
  end
end