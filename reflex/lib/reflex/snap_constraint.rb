require 'reflex/ext'
require 'reflex/constraint'


module Reflex


  class SnapConstraint < Constraint

    def angle=(angle)
      case angle
      when nil     then clear_angle!
      when Range   then set_angle! angle.begin, angle.end
      when Numeric then set_angle! angle,       angle
      else raise ArgumentError, "invalid angle: #{angle.inspect}"
      end
    end

    def angle()
      has_angle! ? Range.new(angle_min!, angle_max!) : nil
    end

    universal_accessor :angle, :motor, :force

  end# SnapConstraint


end# Reflex
