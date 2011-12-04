$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require 'roborabb'

rock_1 = Roborabb.construct(
  bar_length:        4,
  beat_subdivisions: 2,
  lines: {
    hihat: L{|env| true },
    kick:  L{|env| env.beat % 2 == 0 && env.subdivision == 0},
    snare: L{|env| env.beat % 2 == 1 && env.subdivision == 0},
  }
)

puts Roborabb::Lilypond.new(rock_1, bars: 1).to_lilypond
