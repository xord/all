require 'xot/setter'
require 'xot/universal_accessor'
require 'reflex/ext'
require 'reflex/helper'


module Reflex


  class Constraint

    include Xot::Setter
    include HasTags

    def pins()
      [get_pin(0), get_pin(1)]
    end

    def views()
      pins.map(&:view)
    end

    universal_accessor :name, :selector,
      :spring, :damping, collide: {reader: :collide?}

  end# Constraint


end# Reflex
