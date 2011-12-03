Roborabb
========

Generates drumming practice charts.

Example
-------

No output formats are currently supported. Lilypond will be.

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

    rock_1.take(5).each do |x|
      puts x.inspect
    end

Developing
----------

Requires ruby 1.9.
