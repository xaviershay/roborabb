require 'ostruct'
alias :L :lambda

class Roborabb2
  class Bar
    ATTRIBUTES = [:notes, :subdivisions, :unit, :time_signature, :beat_structure]
    attr_reader *ATTRIBUTES

    def initialize(attributes)
      ATTRIBUTES.each do |x|
        send("#{x}=", attributes[x])
      end
    end

    protected

    attr_writer *ATTRIBUTES
  end

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

  def self.construct(plan)
    new(plan)
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

class Roborabb < Struct.new(:opts)
  include Enumerable

  class Bar < Struct.new(:notes, :subdivisions, :unit, :time_signature, :beat_structure)
  end

  def resolve(x, i)
    if x.respond_to?(:call)
      x.call(i)
    else
      x
    end
  end

  def each
    @each ||= Enumerator.new do |yielder|
      i = 0
      while true
        empty_notes = Hash[opts[:lines].keys.map {|x| [x, []] }]
        notes = (0..resolve(opts[:subdivisions], i)-1).inject(empty_notes) do |notes, index|
          env = OpenStruct.new(
            subdivision: index,
            bar:         i
          )
          opts[:lines].map do |key, f|
            notes[key] << f[env]
          end
          notes
        end
        yielder.yield(Bar.new(notes, *opts.values_at(:subdivisions, :unit, :time_signature, :beat_structure).map {|x| resolve(x, i) }))
        i += 1
      end
    end
  end

  def next
    each.next
  end

  def self.construct(opts)
    new(opts)
  end

  class Lilypond < Struct.new(:generator, :opts)
    # Totally incomplete implementation
    def duration(bar, x)
      unit = bar.unit
      [
        unit,
        unit / 2,
        (unit / 2).to_s + ".",
        unit / 4
      ].map(&:to_s)[x-1] || raise("Unsupported duration: #{x}")
    end

    def to_lilypond
      bar = nil
      score = opts[:bars].times.map do
        bar = generator.next 

        lower = self.class.expand(hashslice(bar.notes, :kick, :snare))
        upper = self.class.expand(hashslice(bar.notes, :hihat))

#         $stderr.puts lower.inspect
#         $stderr.puts upper.inspect
#         $stderr.puts
        [
          format_notes(bar, upper),
          format_notes(bar, lower),
          bar
        ]
      end

      upper_notes = score.map {|x| VoicePresenter.new(x[2], x[0]) }
      lower_notes = score.map {|x| VoicePresenter.new(x[2], x[1]) }

      preamble = nil
      upper_voice = upper_notes.map do |note|
        if preamble != note.preamble
          preamble = note.preamble
          preamble + note.notes
        else
          note.notes
        end
      end.join(" |\n ")

      lower_voice = lower_notes.map do |note|
        note.notes
      end.join(" |\n ")


      out = <<-LP
        \\version "2.14.2"
        \\new DrumStaff <<
          \\new DrumVoice {
            \\override Rest #'direction = #up
            \\stemUp   \\drummode {

            #{upper_voice}
           \\bar "|."}}
          \\new DrumVoice {
            \\override Rest #'direction = #down
            \\stemDown \\drummode {
            #{lower_voice}
            } \\bar "|."}
        >>
      LP
    end

    class VoicePresenter < Struct.new(:bar, :notes)
      def beat_structure
        structure = bar.beat_structure
        if structure
          "\\set Staff.beatStructure = #'(%s)" % structure.join(' ')
        end
      end

      def time_signature
        "\\time %s" % (bar.time_signature || "4/4")
      end

      def preamble
        [
          time_signature,
          beat_structure,
        ].compact.join("\n") + "\n"
      end
    end

    def mappings
      {
        kick:  'bd',
        snare: 'sn',
        hihat: 'hh'
      }
    end

    def format_notes(bar, notes)
      notes.map do |note|
        if note[0].length == 1
          mappings[note[0][0]] + duration(bar, note[1]).to_s
        elsif note[0].length > 1
          "<%s>%s" % [
            note[0].map {|x| mappings[x] }.join(' '),
            duration(bar, note[1])
          ]
        else
          "r%s" % duration(bar, note[1])
        end
      end.join(" ")
    end

    def hashslice(hash, *keep_keys)
      h = {}
      keep_keys.each do |key|
        h[key] = hash[key] if hash.has_key?(key)
      end
      h
    end
    def self.expand(notes)
      accum = []
      time  = 0
      out = notes.values.transpose.inject([]) do |out, on_notes|
        on = [*on_notes].map.with_index do |x, i|
          notes.keys[i] if x
        end.compact

        if !on.empty? || time >= 4
          if time > 0
            out << [accum, time]
          end
          accum = on
          time = 0
        end
        time += 1

        out
      end

      out << [accum, time] if time > 0
      out
    end
  end
end
