# -*- coding: utf-8 -*-


require 'xot/universal_accessor'
require 'reflex/shape'


module Reflex


  class PolygonShape < Shape

    universal_accessor :polygon

    def initialize(polygon, *args, &block)
      super(*args, &block)
      self.polygon = polygon
    end

  end# PolygonShape


end# Reflex
