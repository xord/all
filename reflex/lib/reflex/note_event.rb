require 'xot/const_symbol_accessor'
require 'reflex/ext'


module Reflex


  class NoteEvent < Event

    alias get_action action

    const_symbol_reader :action, **{
      none: ACTION_NONE,
      on:   ON,
      off:  OFF
    }

    def on?()
      get_action == ON
    end

    def off?()
      get_action == OFF
    end

    def inspect()
      "#<Reflex::NoteEvent action:%s channel:%d note:%d vel:0f time:%f captured?:%s>" %
        [action, channel, note, velocity, time, captured?]
    end

  end# NoteEvent


end# Reflex
