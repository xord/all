require 'xot/const_symbol_accessor'
require 'reflex/ext'


module Reflex


  class KeyEvent < Event

    alias get_action action

    const_symbol_reader :action, **{
      none: ACTION_NONE,
      down: DOWN,
      up:   UP
    }

    def down?()
      get_action == DOWN
    end

    def up?()
      get_action == UP
    end

    def repeat?()
      repeat >= 1
    end

    def inspect()
      "#<Reflex::KeyEvent action:#{action} chars:'#{chars}' key:#{key} code:#{code} mod:#{modifiers} repeat:#{repeat} captured?:#{captured?}>"
    end

  end# KeyEvent


end# Reflex
