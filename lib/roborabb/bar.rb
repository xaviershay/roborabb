module Roborabb
  class Bar
    ATTRIBUTES = [
      :beat_structure,
      :notes,
      :subdivisions,
      :time_signature,
      :title,
      :unit,
    ]
    attr_reader *ATTRIBUTES

    def initialize(attributes)
      ATTRIBUTES.each do |x|
        send("#{x}=", attributes[x])
      end
    end

    protected

    attr_writer *ATTRIBUTES
  end
end
