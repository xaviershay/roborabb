require 'pp'
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
end
