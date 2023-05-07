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
      "#<Reflex::FrameEvent x:%g(%g) y:%g(%g) w:%g(%g) h:%g(%g) zoom:%g(%g) angle:%g(%g)>" %
        [x, dx, y, dy, w, dw, h, dh, zoom, dzoom, angle, dangle]
    end

  end# FrameEvent


end# Reflex
