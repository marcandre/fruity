require_relative "../lib/fruity"

power = 15
x = 2
n = 30
min = 1
max = 2
s = 10
n.times.map do
  group = Fruity::Group.new(*[->{}] * s, *[->{ 2 + 2 }] * s, :baseline => :none, :samples => 20, :magnify => 1 << power)
  means = group.run.stats.map{|s| s[:mean]}
  noops = means.first(s).sort
  plus  = means.last(s).sort
  min = [min, noops.last / noops.first].max
  max = [max, plus.first / noops.last].min
  p min, max
  raise "Damn, #{min} >= #{max}" if min >= max
end.sort
puts "Threshold between #{min} and #{max} are ok, suggesting #{Math.sqrt(min * max)}"
