$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require 'roborabb'

describe Roborabb2 do
  def notes(rabb)
    rabb.next.notes
  end

  def construct(attributes)
    Roborabb2.construct({
      subdivisions: 2,
      unit:         8,
      notes:        {}
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
  end

end
