# -*- coding: utf-8 -*-


require 'rays/ext'


module Rays


  class Polygon


    class Line < Polyline

      def initialize(*points, loop: true, hole: false)
        setup points, loop, hole
      end

      def transform(matrix = nil, loop: loop?, hole: hole?, &block)
        points = to_a
        points = points.map {|point| matrix * point} if matrix
        points = block.call points if block
        self.class.new(*points, loop: loop, hole: hole)
      end

      def inspect()
        "#<Rays::Polygon::Line #{to_a.join ', '}, loop: #{loop?}, hole: #{hole?}>"
      end

    end# Line


  end# Polygon


end# Rays
