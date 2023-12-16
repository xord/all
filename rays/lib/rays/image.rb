require 'forwardable'
require 'rays/ext'


module Rays


  class Image

    extend Forwardable

    def_delegators :bitmap,           :pixels,  :[]

    def_delegators :bitmap_for_write, :pixels=, :[]=

    def initialize(*args, pixel_density: 1, smooth: false)
      initialize! args, pixel_density, smooth
    end

    def paint(&block)
      painter.paint self, &block
      self
    end

    def size()
      return width, height
    end

    def bounds()
      Bounds.new 0, 0, width, height
    end

    def bitmap(modify = false)
      get_bitmap modify
    end

    private def bitmap_for_write()
      get_bitmap true
    end

  end# Image


end# Rays
