require 'reflex/ext'
require 'reflex/constraint'


module Reflex


  class WheelConstraint < Constraint

    def range=(range)
      case range
      when nil     then clear_range!
      when Range   then set_range! range.begin, range.end
      when Numeric then set_range! range,       range
      else raise ArgumentError, "invalid range: #{range.inspect}"
      end
    end

    def range()
      has_range! ? Range.new(range_min!, range_max!) : nil
    end

    universal_accessor :axis, :range, :motor, :force

  end# WheelConstraint


end# Reflex
