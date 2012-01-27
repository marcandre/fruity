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
  }

  OTHER_OPTIONS = [
    :magnitude,
    :args,
    :self,
    :verbose,
  ]

  OPTIONS = DEFAULT_OPTIONS.keys + OTHER_OPTIONS

  def report(*stuff, &block)
    Fruity::Runner.new(Fruity::Group.new(*stuff, &block)).run
  end

  def compare(*stuff, &block)
    puts report(*stuff, &block)
  end
  extend self
end
