# -*- coding: utf-8 -*-


require 'xot/const_symbol_accessor'
require 'reflex/ext'


module Reflex


  class FocusEvent < Event

    alias get_action action

    const_symbol_reader :action, **{
      none:  ACTION_NONE,
      focus: FOCUS,
      blur:  BLUR
    }

    def focus?()
      get_action == FOCUS
    end

    def blur?()
      get_action == BLUR
    end

    def inspect()
      "#<Reflex::FocusEvent action:#{action} current:#{current} last:#{last}>"
    end

  end# FocusEvent


end# Reflex
