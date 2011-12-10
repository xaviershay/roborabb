$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require 'roborabb'

rock_1 = Roborabb.construct(
  subdivisions:   8,
  unit:           8,
  time_signature: "4/4",
  notes: {
    hihat: L{|env| true },
    kick:  L{|env|
       (env.subdivision % 4 == 0) ||
      ((env.subdivision % 2 == 1) && rand > 0.6)
    },
    snare: L{|env| (env.subdivision + 2) % 4 == 0 },
  }
)

puts Roborabb::Lilypond.new(rock_1, bars: 16).to_lilypond
