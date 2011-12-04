require 'ostruct'
alias :L :lambda

class Roborabb
  def self.construct(opts)
    Enumerator.new do |yielder|
      total_subdivisions = opts[:bar_length] * opts[:beat_subdivisions]
      while true
        empty_bar = Hash[opts[:lines].keys.map {|x| [x, []] }]
        bar = (0..total_subdivisions-1).inject(empty_bar) do |bar, index|
          env = OpenStruct.new(
            beat:       index / opts[:beat_subdivisions],
            subdivision: index % opts[:beat_subdivisions]
          )
          opts[:lines].map do |key, f|
            bar[key] << f[env]
          end
          bar
        end
        yielder.yield(bar)
      end
    end
  end

  class Lilypond < Struct.new(:generator, :opts)
    # Totally incomplete implementation
    def duration(x)
      8 / x
    end

    def to_lilypond
      opts[:bars].times.map do
        bar = generator.next

        lower = self.class.expand(hashslice(bar, :kick, :snare))
        upper = self.class.expand(hashslice(bar, :hihat))

        mappings = {
          kick:  'bd',
          snare: 'sn',
          hihat: 'hh'
        }

        upper_notes = upper.map do |note|
          raise note.inspect if note[0].length != 1
          mappings[note[0][0]] + duration(note[1]).to_s
        end.join(" ")

        lower_notes = lower.map do |note|
          raise note.inspect if note[0].length != 1
          mappings[note[0][0]] + duration(note[1]).to_s
        end.join(" ")

        <<-LP
          \\new DrumStaff <<
            \\new DrumVoice { \\stemUp   \\drummode { #{upper_notes} } }
            \\new DrumVoice { \\stemDown \\drummode { #{lower_notes} }}
          >>
        LP
      end.join
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

        if !on.empty?
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
