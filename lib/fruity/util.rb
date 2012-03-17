require 'benchmark'
module Fruity

  # Utility module doing most of the maths
  #
  module Util
    extend self

    PROPER_TIME_RELATIVE_ERROR = 0.001

    MEASUREMENTS_BY_REALTIME = 2
    MEASUREMENTS_BY_PROPER_TIME = 2 * MEASUREMENTS_BY_REALTIME

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


    APPROX_POWER = 5
    # Calculates the number +n+ that needs to be passed
    # to +real_time+ to get a result that is precise
    # to within +PROPER_TIME_RELATIVE_ERROR+ when compared
    # to the baseline.
    #
    # For example, ->{ sleep(1) } needs only to be run once to get
    # a measurement that will not be affected by the inherent imprecision
    # of the time measurement (or of the inner loop), but ->{ 2 + 2 } needs to be called
    # a huge number of times so that the returned time measurement is not
    # due in big part to the imprecision of the measurement itself
    # or the inner loop itself.
    #
    def sufficient_magnification(exec, options = {})
      mag, delay = sufficient_magnification_and_delay(exec, options)
      mag
    end

    BASELINE_THRESHOLD = 1.02 # Ratio between two identical baselines is typically < 1.02, while {2+2} compared to baseline is typically > 1.02

    def sufficient_magnification_and_delay(exec, options = {})
      power = 0
      min_desired_delta = clock_precision * MEASUREMENTS_BY_PROPER_TIME / PROPER_TIME_RELATIVE_ERROR
      # First, make a gross approximation with a single sample and no baseline
      min_approx_delay = min_desired_delta / (1 << APPROX_POWER)
      while (delay = real_time(exec, options.merge(:magnify => 1 << power))) < min_approx_delay
        power += [Math.log(min_approx_delay.div(delay + clock_precision), 2), 1].max.floor
      end

      # Then take a couple of samples, along with a baseline
      power += 1 unless delay > 2 * min_approx_delay
      group = Group.new(exec, Baseline[exec],
                        options.merge(
                          :baseline => :none,
                          :samples => 5,
                          :filter => [0, 0.25],
                          :magnify => 1 << power
                        ))
      stats = group.run.stats
      if stats[0][:mean] / stats[1][:mean] < 2
        # Quite close to baseline, which means we need to be more discriminant
        power += APPROX_POWER
        stats = group.run(:samples => 40, :magnify => 1 << power).stats
        if stats[0][:mean] / stats[1][:mean] < BASELINE_THRESHOLD
          raise "Given callable can not be reasonably distinguished from an empty block"
        end
      end
      delta = stats[0][:mean] - stats[1][:mean]
      addl_power = [Math.log(min_desired_delta.div(delta), 2), 0].max.floor
      [
        1 << (power + addl_power),
        stats[0][:mean] * (1 << addl_power),
      ]
    end

    # The proper time is the real time taken by calling +exec+
    # number of times given by +options[:magnify]+ minus
    # the real time for calling an empty executable instead.
    #
    # If +options[:magnify]+ is not given, it will be calculated to be meaningful.
    #
    def proper_time(exec, options = {})
      unless options.has_key?(:magnify)
        options = {:magnify => sufficient_magnification(exec, options)}.merge(options)
      end
      real_time(exec, options) - real_time(Baseline[exec], options)
    end

    # Returns the real time taken by calling +exec+
    # number of times given by +options[:magnify]+
    #
    def real_time(exec, options = {})
      GC.start
      GC.disable if options[:disable_gc]
      n = options.fetch(:magnify)
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
