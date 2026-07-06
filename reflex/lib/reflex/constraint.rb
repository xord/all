require 'xot/setter'
require 'xot/universal_accessor'
require 'reflex/ext'


module Reflex


  class Constraint

    include Xot::Setter

    def pins()
      [get_pin(0), get_pin(1)]
    end

    def views()
      pins.map(&:view)
    end

    universal_accessor :spring, :damping, collide: {reader: :collide?}

  end# Constraint


end# Reflex
