$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require 'roborabb'

density = 0.5

generator = Roborabb.construct(
  bar_length:        4,
  beat_subdivisions: 2,
  lines: {
    hihat: L{|env| rand >= 1 - density },
    kick:  L{|env| rand >= 1 - density},
    snare: L{|env| rand >= 1 - density }
  }
)

puts Roborabb::Lilypond.new(generator, bars: 32).to_lilypond
