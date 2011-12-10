$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require 'roborabb'

density = 0.5

templates = [
  [7, 16, "7/16", [3, 2, 2]],
  [5, 8, "5/8", [3, 2]],
  [6, 8, "3/4"],
]

bars = 16.times.map { templates.sample }

generator = Roborabb.construct(
  subdivisions:   L{|bar| bars[bar.index % bars.length][0] },
  unit:           L{|bar| bars[bar.index % bars.length][1] },
  time_signature: L{|bar| bars[bar.index % bars.length][2] },
  beat_structure: L{|bar| bars[bar.index % bars.length][3] },
  notes: {
    hihat: L{|env| rand >= 1 - density },
    kick:  L{|env| rand >= 1 - density},
    snare: L{|env| rand >= 1 - density }
  }
)

puts Roborabb::Lilypond.new(generator, bars: 32).to_lilypond
