module Fruity
  class NamedBlockCollector
    def initialize(to_hash)
      @to_hash = to_hash
    end
  
    def method_missing(method, *args, &block)
      super unless args.empty?
      @to_hash[method] = block
    end
  end
end