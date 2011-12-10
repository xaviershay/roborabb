$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require 'roborabb'

describe Roborabb do
  def notes(rabb)
    rabb.next.notes
  end

  def default_attributes
    {
      subdivisions:   2,
      unit:           8,
      time_signature: '1/4',
      notes:          {}
    }
  end

  def construct(attributes)
    Roborabb.construct(default_attributes.merge(attributes))
  end

  describe '#construct' do
    it 'raises Argument error when no :notes given' do
      lambda {
        Roborabb.construct(default_attributes.delete_if {|k, _| k == :notes })
      }.should raise_error(ArgumentError)
    end
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

    it 'includes title in returned object' do
      rabb = construct(title: "Hello")
      rabb.next.title.should == "Hello"
    end

    it 'includes generated title in returned object' do
      rabb = construct(title: L{|e| "Hello" })
      rabb.next.title.should == "Hello"
    end
  end

end

describe Roborabb::Lilypond do
  describe '#to_lilypond' do
    def bar(attributes = {})
      double("Bar", {
        title:          nil,
        unit:           8,
        notes:          {hihat: [true]},
        time_signature: "4/4",
        beat_structure: [4, 4]
      }.merge(attributes))
    end

    def output(generator, opts = {bars: 1})
      formatter = described_class.new(generator.each, opts)
      formatter.to_lilypond
    end

    it 'outputs rests' do
      generator = [bar(notes: {hihat: [false]})]
      output(generator).should include("r")
    end

    it 'outputs hihats' do
      generator = [bar(notes: {hihat: [true]})]
      output(generator).should include("hh")
    end

    it 'calculates durations correctly to a maximum of four units' do
      generator = [bar(unit: 32, notes: {hihat:
        [true] +
        [true] + [false] * 1 +
        [true] + [false] * 2 +
        [true] + [false] * 3 +
        [true] + [false] * 4
      })]

      output(generator).should include("hh32 hh16 hh16. hh8 hh8 r32")
    end

    it 'outputs kicks and snares' do
      generator = [bar(unit: 4, notes: {
        kick:  [true, false],
        snare: [false, true]
      })]
      output(generator).should include("bd4 sn4")
    end

    it 'can output two notes at the same time' do
      generator = [bar(unit: 4, notes: {kick: [true], snare: [true]})]
      output(generator).should include("<bd sn>4")
    end

    it 'can output a rest before a note' do
      generator = [bar(unit: 8, notes: {hihat: [false, true]})]
      output(generator).should include("r8 hh8")
    end

    it 'includes lilypond preamble' do
      lilypond = output([bar])
      lilypond.should include("\\version")
      lilypond.should include("\\new DrumStaff")
    end

    it 'places hihats and kick/snare in different voices' do
      generator = [bar(unit: 8, notes: {
        hihat: [true, true],
        kick:  [true, false],
        snare: [false, true]
      })]
      voices = output(generator).split("\\new DrumVoice")[1..-1]
      voices[0].should include("hh8 hh8")
      voices[0].should include("\\override Rest #'direction = #up")
      voices[0].should include("\\stemUp")
      voices[1].should include("bd8 sn8")
      voices[1].should include("\\stemDown")
    end

    it 'includes bar lines' do
      generator = [
        bar(notes: {hihat: [true] }),
        bar(notes: {hihat: [false] }),
      ]
      bars = output(generator, bars: 2).split('|')
      bars[0].should include('hh')
      bars[1].should include('r')
    end

    it 'includes time signature changes per bar' do
      generator = [
        bar(time_signature: "1/8"),
        bar(time_signature: "1/8"),
        bar(time_signature: "1/4"),
      ]
      bars = output(generator, bars: 3).split('|')
      bars[0].should     include(%(\\time 1/8))
      bars[1].should_not include(%(\\time))
      bars[2].should     include(%(\\time 1/4))
    end

    it 'includes beat structure changes per bar' do
      generator = [
        bar(beat_structure: [3, 2]),
        bar(beat_structure: [3, 2]),
        bar(beat_structure: [2, 3]),
      ]
      bars = output(generator, bars: 3).split('|')
      bars[0].should     include(%(\\set Staff.beatStructure = #'(3 2)))
      bars[1].should_not include(%(\\set Staff.beatStructure))
      bars[2].should     include(%(\\set Staff.beatStructure = #'(2 3)))
    end

    it 'does not include beat structure if none provided' do
      generator = [
        bar(beat_structure: [3, 2]),
        bar(beat_structure: nil)
      ]
      bars = output(generator, bars: 2).split('|')
      bars[0].should     include(%(\\set Staff.beatStructure = #'(3 2)))
      bars[1].should_not include(%(\\set Staff.beatStructure))
    end

    it 'includes a final double bar line' do
      output([bar]).should include(' \\bar "|."')
    end

    it "includes the final bar's title as the document title" do
      lilypond = output([
        bar(title: 'Wrong'),
        bar(title: 'Hello'),
      ], bars: 2)
      lilypond.should     include(%(title = "Hello"))
      lilypond.should_not include("Wrong")
    end
  end
end
