$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require 'roborabb'

describe 'outputting to lilypond' do
  it 'outputs a basic rock beat' do
    rabb = Roborabb.construct(
      subdivisions:   8,
      unit:           8,
      time_signature: "4/4",
      notes: {
        hihat: ->(env) { true },
        kick:  ->(env) { (env.subdivision + 0) % 4 == 0 },
        snare: ->(env) { (env.subdivision + 2) % 4 == 0 },
      }
    )
    ly = Roborabb::Lilypond.new(rabb, bars: 2)
    output = ly.to_lilypond.lines.map(&:chomp).join
    output.should include('\\time 4/4')
    output.should include('hh8 hh8 hh8 hh8 | hh8 hh8 hh8 hh8')
    output.should include('bd4 sn4 | bd4 sn4')
  end
end
