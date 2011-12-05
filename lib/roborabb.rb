require 'ostruct'
alias :L :lambda

class Roborabb
  class Bar < Struct.new(:notes)
  end

  def self.construct(opts)
    Enumerator.new do |yielder|
      total_subdivisions = opts[:bar_length] * opts[:beat_subdivisions]
      while true
        empty_notes = Hash[opts[:lines].keys.map {|x| [x, []] }]
        notes = (0..total_subdivisions-1).inject(empty_notes) do |notes, index|
          env = OpenStruct.new(
            beat:       index / opts[:beat_subdivisions],
            subdivision: index % opts[:beat_subdivisions]
          )
          opts[:lines].map do |key, f|
            notes[key] << f[env]
          end
          notes
        end
        yielder.yield(Bar.new(notes))
      end
    end
  end

  class Lilypond < Struct.new(:generator, :opts)
    # Totally incomplete implementation
    def duration(x)
      %w(8 4 4. 2)[x-1] || raise("Unsupported duration: #{x}")
    end

    def to_lilypond
      score = opts[:bars].times.map do
        bar = generator.next.notes

        lower = self.class.expand(hashslice(bar, :kick, :snare))
        upper = self.class.expand(hashslice(bar, :hihat))

        [
          format_notes(upper),
          format_notes(lower)
        ]
      end

      upper_notes = score.map(&:first).join(" |\n ")
      lower_notes = score.map(&:last).join(" |\n ")
      <<-LP
        \\version "2.14.2"
        \\new DrumStaff <<
          \\new DrumVoice {
            \\override Rest #'direction = #up
            \\stemUp   \\drummode {
#{upper_notes} } \\bar "|."}
          \\new DrumVoice {
            \\override Rest #'direction = #down
            \\stemDown \\drummode {
#{lower_notes} } \\bar "|."}
        >>
      LP
    end

    def mappings
      {
        kick:  'bd',
        snare: 'sn',
        hihat: 'hh'
      }
    end

    def format_notes(notes)
      notes.map do |note|
        if note[0].length == 1
          mappings[note[0][0]] + duration(note[1]).to_s
        elsif note[0].length > 1
          "<%s>%s" % [
            note[0].map {|x| mappings[x] }.join(' '),
            duration(note[1])
          ]
        else
          "r%s" % duration(note[1])
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
