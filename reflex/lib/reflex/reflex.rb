# -*- coding: utf-8 -*-


require 'reflex/ext'
require 'reflex/window'


module Reflex


  extend module ClassMethods

    def start(*args, &block)
      Application.new(*args, &block).start
    end

    def quit()
      Application.instance.quit
    end

    def window(*args, &block)
      Window.new(*args, &block).tap {|w| w.show}
    end

    self

  end# ClassMethods


end# Reflex
