$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require 'roborabb'

density = 0.5

generator = Roborabb.construct(
  subdivisions:   7,
  unit:           16,
  time_signature: "7/16",
  beat_structure: [3, 2, 2],
  lines: {
    hihat: L{|env| rand >= 1 - density },
    kick:  L{|env| rand >= 1 - density},
    snare: L{|env| rand >= 1 - density }
  }
)

puts Roborabb::Lilypond.new(generator, bars: 32).to_lilypond
