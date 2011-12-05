$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require 'roborabb'


describe Roborabb2 do
  def notes(rabb)
    rabb.next.notes
  end

  describe '.construct' do
    it 'yields subdivision number to generators' do
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
