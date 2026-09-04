require 'reflex/ext'


module Reflex


  class ControlChangeEvent < Event

    def inspect()
      "#<Reflex::ControlChangeEvent channel:%d controller:%d value:%f time:%f captured?:%s>" %
        [channel, controller, value, time, captured?]
    end

  end# ControlChangeEvent


end# Reflex
