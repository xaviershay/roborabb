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
      subdivisions: [0, 1, 0, 1],
    }
  end

  describe 'lilypond output' do
    it 'outputs lilypond code' do
      rabb = Roborabb.construct(
        bar_length: 2,
        beat_subdivisions: 2,
        lines: {
          kick:  L{|env| env.beat % 2 == 0 && env.subdivision == 0},
          snare: L{|env| env.beat % 2 == 1 && env.subdivision == 0},
        }
      )
      output = Roborabb::Lilypond.new(rabb, bars: 1).to_lilypond
      output.should include('bd4 sn4')
    end

    it 'outputs more than one bar' do
      rabb = Roborabb.construct(
        bar_length: 2,
        beat_subdivisions: 2,
        lines: {
          kick:  L{|env| env.beat % 2 == 0 && env.subdivision == 0},
          snare: L{|env| env.beat % 2 == 1 && env.subdivision == 0},
        }
      )
      output = Roborabb::Lilypond.new(rabb, bars: 2).to_lilypond
      output.should include('bd4 sn4 bd4 sn4')
    end
  end
end

describe 'blah' do
  def run(*args)
    Roborabb::Lilypond.expand(*args)
  end

  it 'outputs empty' do
    out = run(
      kick: []
    )
    out.should == []
  end

  it 'outputs rests' do
    out = run(
      kick: [false],
      snare: [false]
    )
    out.should == [[[], 1]]
  end

  it 'outputs rest then note' do
    out = run(
      kick: [false, true]
    )
    out.should == [[[], 1], [[:kick], 1]]
  end

  it 'outputs double notes' do
    out = run(
      kick: [true, true]
    )
    out.should == [[[:kick], 1], [[:kick], 1]]
  end

  it 'works' do
    out = run(
      kick:  [true, false],
      snare: [false, false]
    )
    out.should == [[[:kick], 2]]
  end

  it 'works 2' do
    out = run(
      kick:  [true, false, false, false],
      snare: [false, false, true, false]
    )
    out.should == [[[:kick], 2], [[:snare], 2]]
  end

  it 'works 3' do
    out = run(
      kick:  [true, false, false],
      snare: [false, false, true]
    )
    out.should == [[[:kick], 2], [[:snare], 1]]
  end

  it 'works 4' do
    out = run(
      kick:  [true, false, false],
      snare: [true, false, true]
    )
    out.should == [[[:kick, :snare], 2], [[:snare], 1]]
  end
end
