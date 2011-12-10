require 'ostruct'

require 'roborabb/bar'

module Roborabb
  class Builder
    attr_reader :plan

    def initialize(plan_hash)
      self.plan       = OpenStruct.new(plan_hash)
      self.bar_env    = OpenStruct.new(index: 0)
      self.enumerator = Enumerator.new do |yielder|
        loop do
          yielder.yield(generate_bar)
          bar_env.index += 1
        end
      end
    end

    def next
      enumerator.next
    end

    protected

    def generate_bar
      notes = subdivisions.inject(empty_notes) do |notes, subdivision|
        env = build_env(subdivision)

        plan.notes.map do |name, f|
          notes[name] << resolve(f, env)
        end

        notes
      end

      Bar.new(
        subdivisions:   subdivisions.max + 1,
        unit:           resolve(plan.unit, bar_env),
        time_signature: resolve(plan.time_signature, bar_env),
        beat_structure: resolve(plan.beat_structure, bar_env),
        title:          resolve(plan.title, bar_env),
        notes:          notes
      )
    end

    def resolve(f, env)
      if f.respond_to?(:call)
        f.call(env)
      else
        f
      end
    end

    def subdivisions
      (0...resolve(plan.subdivisions, bar_env))
    end

    def empty_notes
      x = plan.notes.keys.map do |name|
        [name, []]
      end
      Hash[x]
    end

    def build_env(subdivision)
      OpenStruct.new(
        subdivision: subdivision,
        bar:         bar_env
      )
    end

    attr_writer :plan
    attr_accessor :enumerator
    attr_accessor :bar_env
  end
end
