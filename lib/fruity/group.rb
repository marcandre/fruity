module Fruity

  # A group of callable objects
  #
  class Group
    attr_reader :elements
    attr_reader :options

    # Pass either a list of callable objects, a Hash of names and callable objects
    # or an Array of methods names with the option :on specifying which object to call
    # them on (or else the methods are assumed to be global, see the README)
    # Another possibility is to use a block; if it accepts an argument, 
    #
    def initialize(*args, &block)
      @options = DEFAULT_OPTIONS.dup
      @elements = {}
      @counter = 0
      compare(*args, &block)
    end

    # Adds things to compare. See +new+ for details on interface
    #
    def compare(*args, &block)
      if args.last.is_a?(Hash) && (args.last.keys - OPTIONS).empty?
        @options.merge!(args.pop)
      end
      case args.first
        when Hash
          raise ArgumentError, "Expected only one hash of {value => executable}, got #{args.size-1} extra arguments" unless args.size == 1
          raise ArgumentError, "Expected values to be executable" unless args.first.values.all?{|v| v.respond_to?(:call)}
          compare_hash(args.first)
        when Symbol, String
          compare_methods(*args)
        else
          compare_lambdas(*args)
      end
      compare_block(block) if block
    end

    # Returns the maximal sufficient_magnitude for all elements
    # See Util.sufficient_magnitude
    #
    def sufficient_magnitude
      elements.map{|name, exec| Util.sufficient_magnitude(exec, options) }.max
    end

    def size
      elements.size
    end

    def run(options = {})
      Runner.new(self).run(options)
    end

  private
    def compare_hash(h)
      elements.merge!(h)
    end

    def compare_methods(*args)
      on = @options[:on]
      args.each do |m|
        elements[m] = on.method(m)
      end
    end

    def compare_lambdas(*lambdas)
      lambdas.flat_map{|o| Array(o)}
      lambdas.each do |name, callable|
        name, callable = generate_name(name), name unless callable
        raise "Excepted a callable object, got #{callable}" unless callable.respond_to?(:call)
        elements[name] = callable
      end
    end

    def compare_block(block)
      collect = NamedBlockCollector.new(@elements)
      if block.arity == 0
        @options[:self] = block.binding.eval("self")
        collect.instance_eval(&block)
      else
        block.call(collect)
      end
    end

    def generate_name(callable)
      "Code #{@counter += 1}"
    end
  end
end

