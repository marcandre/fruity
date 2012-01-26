module Fruity
  class Runner < Struct.new(:group)
    def run(options = {})
      options = group.options.merge(options)
      options[:magnitude] ||= group.sufficient_magnitude
      timings = options.fetch(:samples).times.map do
        group.elements.map{|name, exec| [Util.real_time(exec, options), Util.real_time(Util::NOOP, options)]}
      end.transpose
      ComparisonRun.new(group, timings)
    end
  end
end