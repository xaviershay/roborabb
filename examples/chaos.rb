$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require 'roborabb'

density = 0.5

SUBDIVISION, UNIT, TIME_SIGNATURE, BEAT_STRUCTURE = *0..3
templates = [
  [7, 16, "7/16", [3, 2, 2]],
  [5, 8,  "5/8",  [3, 2]],
  [6, 8,  "3/4",  nil],
]

bars        = 16.times.map { templates.sample }
random_note = L{|env| rand >= 1 - density }
random_bar  = L{|index|
  L{|bar| bars[bar.index % bars.length][index] }
}

generator = Roborabb.construct(
  title:          "Chaos",
  subdivisions:   random_bar[SUBDIVISION],
  unit:           random_bar[UNIT],
  time_signature: random_bar[TIME_SIGNATURE],
  beat_structure: random_bar[BEAT_STRUCTURE],
  notes: {
    hihat: random_note,
    kick:  random_note,
    snare: random_note
  }
)

puts Roborabb::Lilypond.new(generator, bars: 32).to_lilypond
