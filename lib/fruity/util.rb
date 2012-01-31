require 'benchmark'
module Fruity

  # Utility module doing most of the maths
  #
  module Util
    extend self

    PROPER_TIME_RELATIVE_ERROR = 0.001

    MEASUREMENTS_BY_REALTIME = 2
    MEASUREMENTS_BY_PROPER_TIME = 2 * MEASUREMENTS_BY_REALTIME

    NOOP = Proc.new{}

    # Measures the smallest obtainable delta of two time measurements
    #
    def clock_precision
      @clock_precision ||= 10.times.map do
        t = Time.now
        delta = Time.now - t
        while delta == 0
          delta = Time.now - t
        end
        delta
      end.min
    end

    # Calculates the number +n+ that needs to be passed
    # to +proper_time+ to get a result that is precise
    # to within +PROPER_TIME_RELATIVE_ERROR+
    #
    # For example, ->{ sleep(1) } needs only to be run once to get
    # a measurement that will not be affected by the inherent imprecision
    # of the time measurement, but ->{ 2 + 2 } needs to be called
    # a huge number of times so that the returned time measurement is not
    # due in big part to the imprecision of the measurement itself.
    #
    def sufficient_magnitude(exec, options = {})
      min_desired_result = clock_precision * MEASUREMENTS_BY_PROPER_TIME / PROPER_TIME_RELATIVE_ERROR
      max_iter = 1 << 20
      n = 1
      while (p = proper_time(exec, {:magnitude => n}.merge(options))) < min_desired_result
        raise "Given executable can not be reasonably distinguished from an empty block" if n >= max_iter
        n = [n * [min_desired_result.div(p + clock_precision), 2].max, max_iter].min
      end
      n
    end

    # The proper time is the real time taken by calling +exec+
    # number of times given by +options[:magnitude]+ minus
    # the real time for calling an empty executable instead.
    #
    # If +options[:magnitude]+ is not given, it will be calculated to be meaningful.
    #
    def proper_time(exec, options = {})
      unless options.has_key?(:magnitude)
        options = {:magnitude => sufficient_magnitude(exec, options)}.merge(options)
      end
      real_time(exec, options) - real_time(NOOP, options)
    end

    # Returns the real time taken by calling +exec+
    # number of times given by +options[:magnitude]+
    #
    def real_time(exec, options = {})
      GC.start
      GC.disable if options[:disable_gc]
      n = options.fetch(:magnitude)
      if options.has_key?(:self)
        new_self = options[:self]
        if args = options[:args] and args.size > 0
          Benchmark.realtime{ n.times{ new_self.instance_exec(*args, &exec) } }
        else
          Benchmark.realtime{ n.times{ new_self.instance_eval(&exec) } }
        end
      else
        if args = options[:args] and args.size > 0
          Benchmark.realtime{ n.times{ exec.call(*args) } }
        else
          Benchmark.realtime{ n.times{ exec.call } }
        end
      end
    ensure
      GC.enable
    end

    # Returns the result of calling +exec+
    #
    def result_of(exec, options = {})
      args = (options[:args] || [])
      if options.has_key?(:self)
        options[:self].instance_exec(*args, &exec)
      else
        exec.call(*args)
      end
    end

    # Returns the inherent precision of +proper_time+
    #
    def proper_time_precision
      MEASUREMENTS_BY_PROPER_TIME * clock_precision
    end

    # Calculates stats on some values: {:min, :max, :mean, :sample_std_dev }
    #
    def stats(values)
      sum = values.inject(0, :+)
      # See http://en.wikipedia.org/wiki/Standard_deviation#Rapid_calculation_methods
      q = mean = 0
      values.each_with_index do |x, k|
        prev_mean = mean
        mean += (x - prev_mean) / (k + 1)
        q += (x - mean) * (x - prev_mean)
      end
      sample_std_dev = Math.sqrt( q / (values.size-1) )
      min, max = values.minmax
      {
        :min => min,
        :max => max,
        :mean => mean,
        :sample_std_dev => sample_std_dev
      }
    end

    # Calculates the stats of the difference of +values+ and +baseline+
    # (which can be stats or timings)
    #
    def difference(values, baseline)
      values, baseline = [values, baseline].map{|x| x.is_a?(Hash) ? x : stats(x)}
      {
        :min            => values[:min]  - baseline[:max],
        :max            => values[:max]  - baseline[:min],
        :mean           => values[:mean] - baseline[:mean],
        :sample_std_dev => Math.sqrt(values[:sample_std_dev] ** 2 + values[:sample_std_dev] ** 2),
        # See http://stats.stackexchange.com/questions/6096/correct-way-to-calibrate-means
      }
    end

    # Given two stats +cur+ and +vs+, returns a hash with
    # the ratio between the two, the precision, etc.
    #
    def compare_stats(cur, vs)
      err = (vs[:sample_std_dev] +
             cur[:sample_std_dev] * vs[:mean] / cur[:mean]
            ) / cur[:mean]

      rounding = err > 0 ? -Math.log(err, 10) : 666
      mean = vs[:mean] / cur[:mean]
      {
        :mean     => mean,
        :factor   => (mean).round(rounding),
        :max      => (vs[:mean] + vs[:sample_std_dev]) / (cur[:mean] - cur[:sample_std_dev]),
        :min      => (vs[:mean] - vs[:sample_std_dev]) / (cur[:mean] + cur[:sample_std_dev]),
        :rounding => rounding,
        :precision => 10.0 **(-rounding.round),
      }
    end

    def filter(series, remove_min_ratio, remove_max_ratio = remove_min_ratio)
      series.sort![
        (remove_min_ratio * series.size).floor ...
        ((1-remove_max_ratio) * series.size).ceil
      ]
    end
  end
end
