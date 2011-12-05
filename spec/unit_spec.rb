$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require 'roborabb'


describe Roborabb2 do
  def notes(rabb)
    rabb.next.notes
  end

  describe '.construct' do
    it 'allows a value for notes' do
      rabb = Roborabb2.construct(
        subdivisions: 2,
        notes: {
          subdivisions: 'A'
        }
      )

      notes(rabb).should == {
        subdivisions: ['A', 'A']
      }
    end

    it 'includes subdivision in env yielded to notes' do
      rabb = Roborabb2.construct(
        subdivisions: 3,
        notes: {
          subdivisions: :subdivision.to_proc
        }
      )

      notes(rabb).should == {
        subdivisions: [0, 1, 2]
      }
    end

    it 'includes bar number in env yielded to config' do
      rabb = Roborabb2.construct(
        subdivisions: :index.to_proc,
        notes: { a: 1 }
      )

      3.times.map { notes(rabb) }.should == [
        { a: [] },
        { a: [1] },
        { a: [1, 1] }
      ]
    end

    it 'includes bar number in env yielded to notes' do
      rabb = Roborabb2.construct(
        subdivisions: 2,
        notes: { a: L{|e| e.bar.index } }
      )

      3.times.map { notes(rabb) }.should == [
        { a: [0, 0] },
        { a: [1, 1] },
        { a: [2, 2] }
      ]
    end
  end
end
