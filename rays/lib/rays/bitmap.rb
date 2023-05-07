require 'rays/ext'


module Rays


  class Bitmap

    include Enumerable

    def each()
      height.times do |y|
        width.times do |x|
          yield self[x, y], x, y
        end
      end
    end

    def bounds()
      Bounds.new 0, 0, width, height
    end

    def to_a()
      map {|o| o}
    end

  end# Bitmap


end# Rays
