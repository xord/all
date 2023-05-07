require 'xot/universal_accessor'
require 'reflex/shape'


module Reflex


  class EllipseShape < Shape

    def angle=(range)
      angle_from range.min
      angle_to   range.max
    end

    def angle()
      angle_from..angle_to
    end

    universal_accessor :angle_from, :angle_to, :angle, :hole_size, :nsegment

  end# EllipseShape


end# Reflex
