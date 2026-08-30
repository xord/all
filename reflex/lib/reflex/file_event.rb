require 'xot/const_symbol_accessor'
require 'reflex/ext'


module Reflex


  class FileEvent < Event

    alias get_action action

    const_symbol_reader :action, **{
      none: ACTION_NONE,
      open: FileEvent::OPEN,
      save: FileEvent::SAVE
    }

    def path()
      paths.first
    end

    def open?()
      get_action == FileEvent::OPEN
    end

    def save?()
      get_action == FileEvent::SAVE
    end

    def inspect()
      "#<Reflex::FileEvent #{action} paths:#{paths}>"
    end

  end# FileEvent


end# Reflex
