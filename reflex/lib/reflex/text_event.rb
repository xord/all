require 'xot/const_symbol_accessor'
require 'reflex/ext'


module Reflex


  class TextEvent < Event

    alias get_action action

    const_symbol_reader :action, **{
      none:   ACTION_NONE,
      edit:   EDIT,
      commit: COMMIT
    }

    def edit?()
      get_action == EDIT
    end

    def commit?()
      get_action == COMMIT
    end

    def selection()
      offset = selection_offset!
      return nil if offset < 0
      offset...(offset + selection_size!)
    end

    def inspect()
      "#<Reflex::TextEvent action:%s text:'%s' selection:%s>" %
        [action, text, selection || :nil]
    end

  end# TextEvent


end# Reflex
