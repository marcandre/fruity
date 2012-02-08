require_relative "baseline"
require_relative "util"
require_relative "runner"
require_relative "comparison_run"
require_relative "group"
require_relative "named_block_collector"

Fruity::GLOBAL_SCOPE = self

module Fruity
  DEFAULT_OPTIONS = {
    :on         => GLOBAL_SCOPE,
    :samples    => 20,
    :disable_gc => false,
    :filter     => [0, 0.2],        # Proportion of samples to discard [lower_end, upper_end]
    :baseline   => :single,         # Either :none, :single or :split
  }

  OTHER_OPTIONS = [
    :magnitude,
    :args,
    :self,
    :verbose,
  ]

  OPTIONS = DEFAULT_OPTIONS.keys + OTHER_OPTIONS

  def report(*stuff, &block)
    Fruity::Runner.new(Fruity::Group.new(*stuff, &block)).run(&:feedback)
  end

  def compare(*stuff, &block)
    puts report(*stuff, &block)
  end

  def study(*stuff, &block)
    run = Fruity::Runner.new(Fruity::Group.new(*stuff, &block)).run(:baseline => :single, &:feedback)
    path = run.export
    `open "#{path}"`
    run
  end

  extend self
end
