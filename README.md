Roborabb
========

Generates drumming practice charts in lilypond notation.

Example
-------

    require 'roborabb'

    rock_1 = Roborabb.construct(
      subdivisions:   8,
      unit:           8,
      time_signature: "4/4",
      notes: {
        hihat: L{|env| true },
        kick:  L{|env| (env.subdivision + 0) % 4 == 0 },
        snare: L{|env| (env.subdivision + 2) % 4 == 0 },
      }
    )

    puts Roborabb::Lilypond.new(rock_1, bars: 16).to_lilypond

See `examples` directory for more.

Developing
----------

Requires ruby 1.9.
