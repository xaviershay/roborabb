require 'roborabb/version'

require 'roborabb/core_ext'
require 'roborabb/builder'
require 'roborabb/lilypond'

module Roborabb
  def construct(plan)
    unless plan.has_key?(:notes)
      raise(ArgumentError, "Plan does not contain :notes")
    end
    Builder.new(plan)
  end
  module_function :construct
end

