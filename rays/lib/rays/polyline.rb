require 'rays/ext'


module Rays


  class Polyline

    include Enumerable
    include Comparable

    def initialize(*points, loop: false, fill: nil, colors: nil, texcoords: nil)
      setup points, loop, (fill != nil ? fill : loop), colors, texcoords
    end

    def dup(**kwargs)
      points_, loop_, fill_, colors_, texcoords_ =
        kwargs.values_at :points, :loop, :fill, :colors, :texcoords
      self.class.new(
                 *(points_    || (points?    ? points    : [])),
        loop:      loop_ != nil ? loop_ : loop?,
        fill:      fill_ != nil ? fill_ : fill?,
        colors:    colors_    || (colors?    ? colors    : nil),
        texcoords: texcoords_ || (texcoords? ? texcoords : nil))
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
      return size  <=> o.size  if size  != o.size
      return loop? <=> o.loop? if loop? != o.loop?
      return fill? <=> o.fill? if loop? != o.fill?
      points   .zip(o.points)   .each {|a, b| return a <=> b if a != b}
      colors   .zip(o.colors)   .each {|a, b| return a <=> b if a != b}
      texcoords.zip(o.texcoords).each {|a, b| return a <=> b if a != b}
      0
    end

    def inspect()
      p    = points.map {|o| o.to_a.join ','}.join ', '
      c, t = colors.size, texcoords.size
      "#<Rays::Polyline [#{p}] loop:#{loop?} fill:#{fill?} hole:#{hole?} colors:#{c} texcoords:#{t}>"
    end

  end# Polyline


end# Rays
