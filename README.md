Roborabb
========

Generates drumming practice charts in [lilypond][lilypond] notation.

<img
  src="https://i.imgur.com/7clUyJr.png"
  alt='example score' />

Example
-------

Install the gem:

    gem install roborabb

Then use it:

    require 'roborabb'

    rock_1 = Roborabb.construct(
      title:          "Rock",
      subdivisions:   8,
      unit:           8,
      time_signature: "4/4",
      notes: {
        hihat: ->(env) { true },
        kick:  ->(env) { (env.subdivision + 0) % 4 == 0 },
        snare: ->(env) { (env.subdivision + 2) % 4 == 0 },
      }
    )

    puts Roborabb::Lilypond.new(rock_1, bars: 16).to_lilypond

The resulting file is immediately compilable with [lilypond][lilypond]:

    sudo apt install lilypond # ubuntu lilypond install

    ruby examples/rock.rb > rock.ly && lilypond rock.ly # Generates rock.pdf

See `examples` directory for more.

[lilypond]: http://lilypond.org/

Compatibility
-------------

Only tested on ruby 1.9.3. Requires 1.9, since it uses new style hashes.

Developing
----------

    git clone git://github.com/xaviershay/roborabb.git
    bundle           # Install development dependencies
    bundle exec rake # Runs the specs

Any big new features require an acceptance test, bug fixes should only require
unit tests. Follow the conventions already present.

Status
------

New, but complete.
