module Fruity
  class Runner < Struct.new(:group)
    attr_reader :options, :delay, :timings, :baselines

    def run(options = {})
      prepare(options)
      yield self if block_given?
      sample
    end

    def feedback
      mess = "Running each test " << (options[:magnitude] == 1 ? "once." : "#{options[:magnitude]} times.")
      if d = delay
        if d > 60
          d = (d / 60).round
          unit = "minute"
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
          Util.real_time(exec, options)
        end
      end.transpose
    end

    def sample_baseline_none
      @baselines = nil
      @timings = options.fetch(:samples).times.map do
        group.elements.map do |name, exec|
          Util.real_time(exec, options)
        end
      end.transpose
    end
  end
end
