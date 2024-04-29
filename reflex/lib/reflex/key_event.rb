require 'xot/bit_flag_accessor'
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

    bit_flag_reader :modifiers, **{
      shift:    MOD_SHIFT,
      control:  MOD_CONTROL,
      alt:      MOD_ALT,
      win:      MOD_WIN,
      option:   MOD_OPTION,
      command:  MOD_COMMAND,
      help:     MOD_HELP,
      function: MOD_FUNCTION,
      numpad:   MOD_NUMPAD,
      caps:     MOD_CAPS,
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
