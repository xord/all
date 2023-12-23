require 'rays/ext'
require 'rays/polyline'


module Rays


  class Polygon

    include Enumerable
    include Comparable

    def initialize(*args, loop: true, colors: nil, texcoords: nil)
      setup args, loop, colors, texcoords
    end

    def transform(&block)
      polylines = block.call to_a
      self.class.new(*polylines)
    end

    def intersects(obj)
      !(self & obj).empty?
    end

    def <=>(o)
      (size <=> o.size).then {|cmp|                return cmp if cmp != 0}
      to_a.zip(o.to_a).each {|a, b| cmp = a <=> b; return cmp if cmp != 0}
      0
    end

    def inspect()
      "#<Rays::Polygon [#{map {|polyline| polyline.inspect}.join ', '}]>"
    end

    def self.points(*points)
      points! points
    end

    def self.line(*points, loop: false)
      line! points, loop
    end

    def self.lines(*points)
      lines! points
    end

    def self.triangles(*points, loop: true, colors: nil, texcoords: nil)
      triangles! points, loop, colors, texcoords
    end

    def self.triangle_strip(*points, colors: nil, texcoords: nil)
      triangle_strip! points, colors, texcoords
    end

    def self.triangle_fan(*points, colors: nil, texcoords: nil)
      triangle_fan! points, colors, texcoords
    end

    def self.rect(
      *args, round: nil, lt: nil, rt: nil, lb: nil, rb: nil,
      nsegment: nil)

      rect! args, round, lt, rt, lb, rb, nsegment
    end

    def self.quads(*points, loop: true, colors: nil, texcoords: nil)
      quads! points, loop, colors, texcoords
    end

    def self.quad_strip(*points, colors: nil, texcoords: nil)
      quad_strip! points, colors, texcoords
    end

    def self.ellipse(
      *args, center: nil, radius: nil, hole: nil, from: nil, to: nil,
      nsegment: nil)

      ellipse! args, center, radius, hole, from, to, nsegment
    end

    def self.curve(*points, loop: false)
      curve! points, loop
    end

    def self.bezier(*points, loop: false)
      bezier! points, loop
    end

  end# Polygon


end# Rays
