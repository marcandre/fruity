$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'fruity'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end

RSpec::Matchers.define :be_between do |low,high|
  match do |actual|
    @low, @high = low, high
    actual.between? low, high
  end

  failure_message_for_should do |actual|
    "expected to be between #{@low} and #{@high}, but was #{actual}"
  end

  failure_message_for_should_not do |actual|
    "expected not to be between #{@low} and #{@high}, but was #{actual}"
  end
end

RSpec::Matchers.define :be_array_of_size do |*dimensions|
  match do |actual|
    @dimensions = dimensions
    @actual = []
    while actual.is_a?(Array)
      @actual << actual.size
      actual = actual.first
    end
    @dimensions == @actual
  end

  failure_message_for_should do |actual|
    "expected to be an array of dimension #{@dimensions.join('x')} but was #{@actual.join('x')}"
  end

  failure_message_for_should_not do |actual|
    "expected not to be an array of dimension #{@dimensions.join('x')}"
  end
end
