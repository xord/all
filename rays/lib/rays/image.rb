# -*- coding: utf-8 -*-


require 'forwardable'
require 'rays/ext'


module Rays


  class Image

    extend Forwardable

    def_delegators :bitmap, :[], :[]=

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

  end# Image


end# Rays
