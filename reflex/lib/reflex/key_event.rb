require 'xot/bit_flag_accessor'
require 'xot/const_symbol_accessor'
require 'reflex/ext'
require 'reflex/helper'


module Reflex


  class KeyEvent < Event

    alias get_action action

    const_symbol_reader :action, **{
      none: ACTION_NONE,
      down: DOWN,
      up:   UP
    }

    bit_flag_reader :modifiers, **MODIFIER_SYMBOLS

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
      "#<Reflex::KeyEvent action:%s chars:%s key:%s code:0x%X mod:%s repeat:%d captured?:%s>" % [
        action,
        chars ? "'#{chars}'" : :nil,
        key ? key : :nil,
        code,
        modifiers.join(','),
        repeat,
        captured?
      ]
    end

  end# KeyEvent


end# Reflex
