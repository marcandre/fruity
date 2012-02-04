module Fruity
  class Runner < Struct.new(:group)
    def run(options = {})
      options = group.options.merge(options)
      options[:magnitude] ||= group.sufficient_magnitude
      baselines = []
      timings = options.fetch(:samples).times.map do
        case options.fetch(:baseline)
        when :split
          baselines << (bl = [])
        when :single
          baselines << Util.real_time(Baseline[group.elements.first.value], options)
        when :none
        else
          raise ArgumentError, "Unrecognized :baseline option: #{options.fetch(:baseline)}"
        end
        mess << " Test will take about #{d.ceil} #{unit || 'second'}#{d > 1 ? 's' : ''}."
      end
      puts mess
    end

  private
    def prepare(opt)
      @options = group.options.merge(opt)
      unless options[:magnitude]
        options[:magnitude], @delay = group.sufficient_magnitude_and_delay
        @delay *= options.fetch(:samples)
      end
    end

    def sample
      send(:"sample_baseline_#{options.fetch(:baseline)}")
      ComparisonRun.new(group, timings, baselines)
    end

    def sample_baseline_split
      baselines = group.elements.map{|name, exec| Baseline[exec]}
      exec_and_baselines = group.elements.values.zip(baselines)
      @baselines, @timings = options.fetch(:samples).times.map do
        exec_and_baselines.flat_map do |exec, baseline|
          [
            Util.real_time(baseline, options),
            Util.real_time(exec, options),
          ]
        end
      end.transpose.each_slice(2).to_a.transpose
    end

    def sample_baseline_single
      baseline = Baseline[group.elements.first.last]
      @baselines = []
      @timings = options.fetch(:samples).times.map do
        baselines << Util.real_time(baseline, options)
        group.elements.map do |name, exec|
          bl << Util.real_time(Baseline[exec], options) if bl
          Util.real_time(exec, options)
        end
      end.transpose

      case options.fetch(:baseline)
      when :split
        baselines = baselines.transpose
      when :none
        baselines = nil
      end

      ComparisonRun.new(group, timings, baselines)
    end
  end
end
