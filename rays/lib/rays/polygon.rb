# -*- coding: utf-8 -*-


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

    def self.line(*args, loop: false)
      new(*args, loop: loop)
    end

    def self.rect(
      *args, round: nil, lt: nil, rt: nil, lb: nil, rb: nil, nsegment: nil)

      create_rect args, round, lt, rt, lb, rb, nsegment
    end

    def self.ellipse(
      *args, center: nil, radius: nil, hole: nil, from: nil, to: nil,
      nsegment: nil)

      create_ellipse args, center, radius, hole, from, to, nsegment
    end

    def self.curve(*args, loop: false)
      create_curve args, loop
    end

    def self.bezier(*args, loop: false)
      create_bezier args, loop
    end

  end# Polygon


end# Rays
