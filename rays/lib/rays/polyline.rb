# -*- coding: utf-8 -*-


require 'rays/ext'


module Rays


  class Polyline

    include Enumerable

    def initialize(*points, loop: false)
      setup points, loop
    end

    def transform(matrix = nil, loop: loop?, &block)
      points = to_a
      points = points.map {|point| matrix * point} if matrix
      points = block.call points if block
      self.class.new(*points, loop: loop)
    end

    def inspect()
      "#<Rays::Polyline #{to_a.join ', '}, loop: #{loop?}>"
    end

  end# Polyline


end# Rays
