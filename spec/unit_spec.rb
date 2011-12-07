$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require 'roborabb'

describe Roborabb2 do
  def notes(rabb)
    rabb.next.notes
  end

  def construct(attributes)
    Roborabb2.construct({
      subdivisions:   2,
      unit:           8,
      time_signature: '1/4',
      notes:          {}
    }.merge(attributes))
  end

  describe '#next' do
    it 'allows a value for notes' do
      rabb = construct(
        subdivisions: 2,
        notes:        { a: 'A' }
      )

      notes(rabb).should == { a: ['A', 'A'] }
    end

    it 'includes subdivision in env yielded to notes' do
      rabb = construct(
        subdivisions: 3,
        notes: {
          a: :subdivision.to_proc
        }
      )

      notes(rabb).should == { a: [0, 1, 2] }
    end

    it 'includes bar number in env yielded to config' do
      rabb = construct(
        subdivisions: L{|e| e.index + 1 },
        notes:        { a: 1 }
      )

      3.times.map { notes(rabb) }.should == [
        { a: [1] },
        { a: [1, 1] },
        { a: [1, 1, 1] }
      ]
    end

    it 'includes bar number in env yielded to notes' do
      rabb = construct(
        subdivisions: 2,
        notes:        { a: L{|e| e.bar.index } }
      )

      3.times.map { notes(rabb) }.should == [
        { a: [0, 0] },
        { a: [1, 1] },
        { a: [2, 2] }
      ]
    end

    it 'includes subdivisons in returned object' do
      rabb = construct(subdivisions: 2)
      rabb.next.subdivisions.should == 2
    end

    it 'includes unit in returned object' do
      rabb = construct(unit: 8)
      rabb.next.unit.should == 8
    end

    it 'includes generated unit in returned object' do
      rabb = construct(unit: L{|e| 8 })
      rabb.next.unit.should == 8
    end

    it 'includes time_signature in returned object' do
      rabb = construct(time_signature: "7/8")
      rabb.next.time_signature.should == "7/8"
    end

    it 'includes generated time_signature in returned object' do
      rabb = construct(time_signature: L{|e| "7/8" })
      rabb.next.time_signature.should == "7/8"
    end

    it 'includes beat_structure in returned object' do
      rabb = construct(beat_structure: [3, 2, 2])
      rabb.next.beat_structure.should == [3, 2, 2]
    end

    it 'includes generated beat_structure in returned object' do
      rabb = construct(beat_structure: L{|e| [3, 2, 2] })
      rabb.next.beat_structure.should == [3, 2, 2]
    end
  end

end

describe Roborabb2::Lilypond do
  describe '#to_lilypond' do
    it 'outputs rests' do
      generator = [stub(unit: 8, notes: {hihat: [false]})].each
      formatter = described_class.new(generator, bars: 1)
      formatter.to_lilypond.should include("r8")
    end

    it 'outputs hihats' do
      generator = [stub(unit: 8, notes: {hihat: [true]})].each
      formatter = described_class.new(generator, bars: 1)
      formatter.to_lilypond.should include("hh8")
    end

    it 'calculates durations correctly to a maximum of four units' do
      generator = [stub(unit: 32, notes: {hihat:
        [true] +
        [true] + [false] * 1 +
        [true] + [false] * 2 +
        [true] + [false] * 3 +
        [true] + [false] * 4
      })].each

      formatter = described_class.new(generator, bars: 1)
      formatter.to_lilypond.should include("hh32 hh16 hh16. hh8 hh8 r32")
    end

    it 'outputs kicks and snares' do
      generator = [stub(unit: 4, notes: {kick: [true, false], snare: [false, true]})].each
      formatter = described_class.new(generator, bars: 1)
      formatter.to_lilypond.should include("bd4 sn4")
    end

    it 'can output two notes at the same time' do
      generator = [stub(unit: 4, notes: {kick: [true], snare: [true]})].each
      formatter = described_class.new(generator, bars: 1)
      formatter.to_lilypond.should include("<bd sn>4")
    end

    it 'can output a rest before a note' do
      generator = [stub(unit: 8, notes: {hihat: [false, true]})].each
      formatter = described_class.new(generator, bars: 1)
      formatter.to_lilypond.should include("r8 hh8")
    end
  end
end
