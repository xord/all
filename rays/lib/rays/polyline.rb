require 'rays/ext'


module Rays


  class Polyline

    include Enumerable
    include Comparable

    def initialize(
      *points, loop: false, fill: nil, colors: nil, texcoords: nil, hole: false)

      setup points, loop, (fill != nil ? fill : loop), colors, texcoords, hole
    end

    def dup(**kwargs)
      points_, loop_, fill_, colors_, texcoords_, hole_ =
        kwargs.values_at :points, :loop, :fill, :colors, :texcoords, :hole
      self.class.new(
                 *(points_    || (points?    ? points    : [])),
        loop:      loop_ != nil ? loop_ : loop?,
        fill:      fill_ != nil ? fill_ : fill?,
        colors:    colors_    || (colors?    ? colors    : nil),
        texcoords: texcoords_ || (texcoords? ? texcoords : nil),
        hole:      hole_ != nil ? hole_ : hole?)
    end

    def points()
      each_point.to_a
    end

    def colors()
      each_color.to_a
    end

    def texcoords()
      each_texcoord.to_a
    end

    def each_point(&block)
      block ? each_point!(&block) : enum_for(:each_point!)
    end

    def each_color(&block)
      block ? each_color!(&block) : enum_for(:each_color!)
    end

    def each_texcoord(&block)
      block ? each_texcoord!(&block) : enum_for(:each_texcoord!)
    end

    alias each each_point

    def <=>(o)
      (size  <=> o.size) .then {|cmp|                        return cmp if cmp != 0}
      (loop? <=> o.loop?).then {|cmp|                        return cmp if cmp != 0}
      (fill? <=> o.fill?).then {|cmp|                        return cmp if cmp != 0}
      points   .zip(o.points)   .each {|a, b| cmp = a <=> b; return cmp if cmp != 0}
      colors   .zip(o.colors)   .each {|a, b| cmp = a <=> b; return cmp if cmp != 0}
      texcoords.zip(o.texcoords).each {|a, b| cmp = a <=> b; return cmp if cmp != 0}
      0
    end

    def inspect()
      p    = points.map {|o| o.to_a.join ','}.join ', '
      c, t = colors.size, texcoords.size
      "#<Rays::Polyline [#{p}] loop:#{loop?} fill:#{fill?} hole:#{hole?} colors:#{c} texcoords:#{t}>"
    end

  end# Polyline


end# Rays
