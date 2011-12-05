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

    it 'yields subdivision number to notes' do
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
  end
end
