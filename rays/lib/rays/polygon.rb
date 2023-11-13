require 'rays/ext'
require 'rays/polyline'


module Rays


  class Polygon

    include Enumerable

    def initialize(*args, loop: true)
      setup args, loop
    end

    def transform(matrix = nil, &block)
      lines = to_a
      lines = lines.map {|line| line.transform matrix} if matrix
      lines = block.call lines if block
      self.class.new(*lines)
    end

    def intersects(obj)
      !(self & obj).empty?
    end

    def self.points(*args)
      points! args
    end

    def self.lines(*args)
      lines! args
    end

    def self.line_strip(*args, loop: false)
      line_strip! args, loop
    end

    def self.triangles(*args, loop: true)
      triangles! args, loop
    end

    def self.triangle_strip(*args)
      triangle_strip! args
    end

    def self.triangle_fan(*args)
      triangle_fan! args
    end

    def self.quads(*args, loop: true)
      quads! args, loop
    end

    def self.quad_strip(*args)
      quad_strip! args
    end

    def self.rect(
      *args, round: nil, lt: nil, rt: nil, lb: nil, rb: nil,
      nsegment: nil)

      rect! args, round, lt, rt, lb, rb, nsegment
    end

    def self.ellipse(
      *args, center: nil, radius: nil, hole: nil, from: nil, to: nil,
      nsegment: nil)

      ellipse! args, center, radius, hole, from, to, nsegment
    end

    def self.curve(*args, loop: false)
      curve! args, loop
    end

    def self.bezier(*args, loop: false)
      bezier! args, loop
    end

  end# Polygon


end# Rays
