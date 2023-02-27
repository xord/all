# -*- coding: utf-8 -*-


require 'rays/ext'


module Rays


  class Point

    include Comparable
    include Enumerable

    def move_to(*args)
      dup.move_to!(*args)
    end

    def move_by(*args)
      dup.move_by!(*args)
    end

    def zero?()
      length == 0
    end

    def each(&block)
      to_a.each(&block)
    end

    def to_a(dimension = 2)
      case dimension
      when 1 then [x]
      when 2 then [x, y]
      when 3 then [x, y, z]
      when 4 then [x, y, z, 1.0]
      else raise ArgumentError
      end
    end

    def to_s(dimension = 2)
      to_a(dimension).to_s
    end

    def <=>(o)
      ret = x <=> o.x; return ret if ret != 0
      ret = y <=> o.y; return ret if ret != 0
            z <=> o.z
    end

    def inspect()
      "#<Rays::Point #{to_a(3).join ', '}>"
    end

  end# Point


end# Rays
