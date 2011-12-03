$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require 'roborabb'

describe Roborabb do
  it 'can generate a simple beat' do
    rabb = Roborabb.construct(
      bar_length: 1,
      beat_subdivisions: 1,
      lines: {
        hihat: L{|env| true },
        snare: L{|env| false }
      }
    )

    rabb.next.should == {
      hihat: [true],
      snare: [false]
    }
  end

  it 'yields beat number to generators' do
    rabb = Roborabb.construct(
      bar_length: 2,
      beat_subdivisions: 2,
      lines: {
        beats:        L{|env| env.beat },
      }
    )

    rabb.next.should == {
      beats: [0, 0, 1, 1]
    }
  end

  it 'yields subdivision number to generators' do
    rabb = Roborabb.construct(
      bar_length: 2,
      beat_subdivisions: 2,
      lines: {
        subdivisions: L{|env| env.subdivision },
      }
    )

    rabb.next.should == {
      subdivisions: [0, 1, 0, 1]
    }
  end
end
