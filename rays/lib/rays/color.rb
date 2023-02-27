# -*- coding: utf-8 -*-


require 'rays/ext'


module Rays


  class Color

    include Comparable
    include Enumerable

    alias r= red=
    alias r  red

    alias g= green=
    alias g  green

    alias b= blue=
    alias b  blue

    alias a= alpha=
    alias a  alpha

    def opaque?()
      alpha >= 1
    end

    def transparent?()
      alpha <= 0
    end

    def translucent?()
      a = alpha
      0 < a && a < 1
    end

    def each(&block)
      to_a.each(&block)
    end

    def to_a()
      [red, green, blue, alpha]
    end

    def to_s()
      to_a.to_s
    end

    def [](index)
      case index
      when 0 then red
      when 1 then green
      when 2 then blue
      when 3 then alpha
      else raise IndexError
      end
    end

    def []=(index, val)
      case index
      when 0 then self.red   = val
      when 1 then self.green = val
      when 2 then self.blue  = val
      when 3 then self.alpha = val
      else raise IndexError
      end
    end

    def <=>(o)
      ret = red   <=> o.red;   return ret if ret != 0
      ret = green <=> o.green; return ret if ret != 0
      ret = blue  <=> o.blue;  return ret if ret != 0
            alpha <=> o.alpha
    end

    def hash()
      red.hash + green.hash + blue.hash + alpha.hash
    end

    def eql?(o)
      self == o
    end

    def inspect()
      "#<#{self.class.name} #{to_s}>"
    end

  end# Color


end# Rays
