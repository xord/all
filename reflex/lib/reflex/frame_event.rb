require 'reflex/ext'


module Reflex


  class FrameEvent < Event

    alias dw   dwidth
    alias dh   dheight
    alias dd   ddepth
    alias dpos dposition

    def x()
      frame.x
    end

    def y()
      frame.y
    end

    def z()
      frame.z
    end

    def width()
      frame.width
    end

    def height()
      frame.height
    end

    def depth()
      frame.depth
    end

    alias w width
    alias h height
    alias d depth

    def inspect()
      "#<Reflex::FrameEvent x:%g(%g) y:%g(%g) z:%g(%g) w:%g(%g) h:%g(%g) d:%g(%g) zoom:%g(%g) angle:%g(%g)>" %
        [x, dx, y, dy, z, dz, w, dw, h, dh, d, dd, zoom, dzoom, angle, dangle]
    end

  end# FrameEvent


end# Reflex
