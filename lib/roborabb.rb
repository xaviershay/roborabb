require 'ostruct'
alias :L :lambda

require 'roborabb/version'

class Roborabb
  class Lilypond
    def initialize(generator, opts)
      self.generator = generator
      self.opts      = opts
    end

    def to_lilypond
      score = opts[:bars].times.map do
        bar = generator.next

        format_bar(bar)
      end

      lilypond do
        voice(:up)   { format_bars(score, :upper) } +
        voice(:down) { format_bars(score, :lower) }
      end
    end

    protected

    attr_accessor :generator, :opts, :title

    def format_bars(bars, voice)
      last_plan = Bar.new({})
      bars.map do |bar|
        plan = bar[:bar]

        preamble = ""
        if last_plan.time_signature != plan.time_signature
          preamble += %(\\time #{plan.time_signature}\n)
        end

        if last_plan.beat_structure != plan.beat_structure && plan.beat_structure
          preamble += %(\\set Staff.beatStructure = #'(%s)\n) % [
            plan.beat_structure.join(' ')
          ]
        end
        last_plan = plan
        self.title = plan.title

        preamble + bar[voice]
      end.join(' | ') + ' \\bar "|."'
    end

    def lilypond
      # Evaluating the content first is necessary to infer the title.
      content = yield

      <<-LP
      \\version "2.14.2"
      \\header {
        title = "#{title}"
        subtitle = " "
      }
      \\new DrumStaff <<
        #{content}
      >>
      LP
    end

    def voice(direction)
      result = <<-LP
      \\new DrumVoice {
        \\override Rest #'direction = ##{direction}
        \\stem#{direction == :up ? "Up" : "Down"}   \\drummode {
          #{yield}
        }
      }
      LP
    end

    def format_bar(bar)
      {
        bar:   bar,
        upper: format_notes(bar, expand(hashslice(bar.notes, :hihat))),
        lower: format_notes(bar, expand(hashslice(bar.notes, :kick, :snare)))
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

    def mappings
      {
        kick:  'bd',
        snare: 'sn',
        hihat: 'hh'
      }
    end

    def duration(bar, x)
      unit = bar.unit
      [
        unit,
        unit / 2,
        (unit / 2).to_s + ".",
        unit / 4
      ].map(&:to_s)[x-1] || raise("Unsupported duration: #{x}")
    end

    def hashslice(hash, *keep_keys)
      h = {}
      keep_keys.each do |key|
        h[key] = hash[key] if hash.has_key?(key)
      end
      h
    end

    def expand(notes)
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
    unless plan.has_key?(:notes)
      raise(ArgumentError, "Plan does not contain :notes")
    end
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
