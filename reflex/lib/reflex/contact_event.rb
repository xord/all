require 'xot/const_symbol_accessor'
require 'reflex/ext'


module Reflex


  class ContactEvent < Event

    alias get_action action

    const_symbol_reader :action, **{
      none:  ACTION_NONE,
      begin: ContactEvent::BEGIN,
      end:   ContactEvent::END
    }

    def begin?()
      get_action == ContactEvent::BEGIN
    end

    def end?()
      get_action == ContactEvent::END
    end

    def inspect()
      "#<Reflex::ContactEvent #{action} shape:#{shape} view:#{view}>"
    end

  end# ContactEvent


end# Reflex
