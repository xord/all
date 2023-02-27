# -*- coding: utf-8 -*-


require 'reflex/ext'


module Reflex


  class FrameEvent < Event

    alias dw   dwidth
    alias dh   dheight
    alias dpos dposition

    def x()
      frame.x
    end

    def y()
      frame.y
    end

    def width()
      frame.width
    end

    def height()
      frame.height
    end

    alias w width
    alias h height

    def inspect()
      "#<Reflex::FrameEvent x:#{x} y:#{y} w:#{w} h:#{h} dx:#{dx} dy:#{dy} dw:#{dw} dh:#{dh}>"
    end

  end# FrameEvent


end# Reflex
