module Fruity

  # Utility module for building
  # baseline equivalents for callables.
  #
  module Baseline
    extend self

    # Returns the baseline for the given callable object
    # The signature (number of arguments) and type (proc, ...)
    # will be copied as much as possible.
    #
    def [](exec)
      kind = callable_kind(exec)
      signature = callable_signature(exec)
      NOOPs[kind][signature] ||= build_baseline(kind, signature)
    end

    NOOPs = Hash.new{|h, k| h[k] = {}}

    def callable_kind(exec)
      if exec.is_a?(Method)
        exec.source_location ? :method : :builtin_method
      elsif exec.lambda?
        :lambda
      else
        :proc
      end
    end

    def callable_signature(exec)
      if exec.respond_to?(:parameters)
        exec.parameters.map(&:first)
      else
        # Ruby 1.8 didn't have parameters, so rely on arity
        opt = exec.arity < 0
        req = opt ? -1-exec.arity : exec.arity
        signature = [:req] * req
        signature << :rest if opt
        signature
      end
    end

    PARAM_MAP = {
      :req => "%{name}",
      :opt => "%{name} = nil",
      :rest => "*%{name}",
      :block => "&%{name}",
    }

    def arg_list(signature)
      signature.map.with_index{|kind, i| PARAM_MAP[kind] % {:name => "p#{i}"}}.join(",")
    end

    def build_baseline(kind, signature)
      args = "|#{arg_list(signature)}|"
      case kind
      when :lambda, :proc
        eval("#{kind}{#{args}}")
      when :builtin_method
        case signature
        when []
          nil.method(:nil?)
        when [:req]
          nil.method(:==)
        else
          Array.method(:[])
        end
      when :method
        @method_counter ||= 0
        @method_counter += 1
        name = "baseline_#{@method_counter}"
        eval("define_method(:#{name}){#{args}}")
        method(name)
      end
    end
  end
end
  