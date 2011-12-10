$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require 'roborabb'

states       = ([true, false] * 4).combination(4).to_a.uniq
lower_states = ([0, 1, 2]     * 4).combination(4).to_a.uniq

generator = Roborabb.construct(
  subdivisions:   16,
  unit:           16,
  time_signature: "4/4",
  notes: {
    hihat: L{|env|
      states[(env.bar.index / lower_states.length) % states.length][env.subdivision % 4]
    },
    kick:  L{|env|
      lower_states[env.bar.index % lower_states.length][env.subdivision % 4] == 1
    },
    snare: L{|env|
      lower_states[env.bar.index % lower_states.length][env.subdivision % 4] == 2
    }
  }
)

bars = states.length * lower_states.length
puts Roborabb::Lilypond.new(generator, bars: bars).to_lilypond
