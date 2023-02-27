# -*- coding: utf-8 -*-


require 'reflex/image'
require 'reflex/bitmap'
require 'reflex/view'


module Reflex


  class TextView < View

    has_model

    attr_accessor :font

    alias text= data=
    alias text  data

    def content_bounds()
      s = string
      return 0, 0 unless s && window
      font = @font || window.painter.font
      [font.width(s), font.height].map &:ceil
    end

    def on_draw(e)
      s = string
      e.painter.push font: @font do
        text s
      end
    end

  end# TextView


end# Reflex
