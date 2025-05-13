require 'xot/const_symbol_accessor'
require 'reflex/ext'


module Reflex


  class MIDIEvent < Event

    alias get_action action

    const_symbol_reader :action, **{
      none:              ACTION_NONE,
      note_on:           NOTE_ON,
      note_off:          NOTE_OFF,
      control_change:    CONTROL_CHANGE,
      program_change:    PROGRAM_CHANGE,
      channel_pressure:  CHANNEL_PRESSURE,
      key_pressure:      KEY_PRESSURE,
      pitch_bend_change: PITCH_BEND_CHANGE,
      system:            SYSTEM
    }

    def note_on?()
      get_action == NOTE_ON
    end

    def note_off?()
      get_action == NOTE_OFF
    end

    def control_change?()
      get_action == CONTROL_CHANGE
    end

    alias cc? control_change?

    def program_change?()
      get_action == PROGRAM_CHANGE
    end

    alias pc? program_change?

    def channel_pressure?()
      get_action == CHANNEL_PRESSURE
    end

    def key_pressure?()
      get_action == KEY_PRESSURE
    end

    def pitch_bend_change?()
      get_action == PITCH_BEND_CHANGE
    end

    def system?()
      get_action == SYSTEM
    end

    def inspect()
      "#<Reflex::MIDIEvent action:%s channel:%d data:[%d, %d] captured?:%s>" %
        [action, channel, data1, data2, captured?]
    end

  end# NoteEvent


end# Reflex
