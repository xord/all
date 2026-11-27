require 'reflex/ext'


module Reflex


  class MIDI

    def self.inputs()
      all.select(&:input?)
    end

    def self.outputs()
      all.select(&:output?)
    end

    def note_on(note, velocity, channel: 0)
      note_on! note, velocity, channel
    end

    def note_off(note, velocity = 0, channel: 0)
      note_off! note, velocity, channel
    end

    def control_change(controller, value, channel: 0)
      control_change! controller, value, channel
    end

  end# MIDI


end# Reflex
