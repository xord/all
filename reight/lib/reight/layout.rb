# Declarative widget layout.
#
#   Reight::Layout.apply width, height do
#     space Reight::App::NAVIGATOR_HEIGHT
#     row pad: 6, gap: 6 do
#       put page_prev, w: 12, h: 12
#       spacer
#       put remove,    w: 12, h: 12
#     end
#     put canvas, aspect: 1, align: :center
#   end
#
# Containers (row/column/grid) place children along their main axis.
# Main axis sizes: a Numeric is fixed, :fill takes a share of the
# leftover space (the default for widgets), and containers default to
# hugging their contents. On the cross axis a Numeric is fixed and nil
# stretches; fixed-size children are placed by align: (:start, :center
# or :end). aspect: (= w / h) derives one dimension from the other, so
# only use it where the other dimension is determined.
#
# stack layers children on the same box; a child with at: [x, y] is
# offset from the stack origin instead (for floating widgets).
#
# Blocks are instance_exec'd on a Builder; unknown methods fall through
# to the caller, so widget accessors can be used directly. Beware that
# methods added to Object by the 'using Reight' refinement win over
# this fallthrough (currently only width/height collide, and both
# return the same values); if a name ever collides, capture it in a
# local variable before the block.
#
class Reight::Layout

  def self.apply(width, height, delegate: nil, &block)
    root = Group.new dir: :v
    Builder.new(root, delegate || block.binding.receiver).instance_exec(&block)
    root.place__ 0, 0, width, height
    [].tap {root.widgets__ _1}
  end


  # @private
  class Node

    def initialize(w: nil, h: nil, align: nil, at: nil)
      @w, @h, @align, @at = w, h, align, at
    end

    attr_reader :align, :at

    def spec(dir)   = dir == :h ? @w : @h

    def cspec(dir)  = dir == :h ? @h : @w

    def flex?(dir)  = !spec(dir).is_a?(Numeric)

    def weight(dir) = flex?(dir) ? 1 : 0

    # size along dir; cross is the container's inner cross size
    def natural(dir, cross) =
      spec(dir).is_a?(Numeric) ? spec(dir) : 0

    # size across dir, once the size along dir is known
    def cross_size(dir, cross, main) =
      cspec(dir).is_a?(Numeric) ? cspec(dir) : cross

    def place__(x, y, w, h) = nil

    def widgets__(list)     = nil

  end# Node


  # @private
  class Item < Node

    def initialize(widget, aspect: nil, **kwargs)
      super(**kwargs)
      @widget, @aspect = widget, aspect
    end

    def flex?(dir) = super && !@aspect

    def natural(dir, cross)
      s = spec dir
      return s if s.is_a? Numeric
      if @aspect
        c = cspec(dir).is_a?(Numeric) ? cspec(dir) : cross
        return dir == :h ? c * @aspect : c / @aspect
      end
      0
    end

    def cross_size(dir, cross, main)
      c = cspec dir
      return c if c.is_a? Numeric
      return dir == :h ? main / @aspect : main * @aspect if @aspect
      cross
    end

    def place__(x, y, w, h)
      sp                     = @widget.respond_to?(:sprite) ? @widget.sprite : @widget
      sp.x, sp.y, sp.w, sp.h = [x, y, w, h].map(&:round)
    end

    def widgets__(list) = list.push(@widget)

  end# Item


  # @private
  class FixedSpace < Node

    def initialize(size)
      super()
      @size = size
    end

    def flex?(dir)                   = false

    def natural(dir, cross)          = @size

    def cross_size(dir, cross, main) = 0

  end# FixedSpace


  # @private
  class Spacer < Node

    def initialize(weight)
      super()
      @weight = weight
    end

    def flex?(dir)                   = true

    def weight(dir)                  = @weight

    def cross_size(dir, cross, main) = 0

  end# Spacer


  # @private
  class Group < Node

    def initialize(dir:, gap: 0, pad: 0, **kwargs)
      super(**kwargs)
      @dir, @gap, @pad, @children = dir, gap, pad, []
    end

    def add(node) = @children.push(node).then {node}

    def flex?(dir) = spec(dir) == :fill

    def natural(dir, cross)
      s = spec dir
      return s if s.is_a? Numeric
      inner = [cross - @pad * 2, 0].max
      @pad * 2 +
        if dir == @dir
          @children.sum {_1.natural dir, inner} + @gap * [@children.size - 1, 0].max
        else
          @children.map {_1.natural dir, inner}.max || 0
        end
    end

    def place__(x, y, w, h)
      x, y  = x + @pad,     y + @pad
      w, h  = w - @pad * 2, h - @pad * 2
      main  = @dir == :h ? w : h
      cross = @dir == :h ? h : w
      gaps  = @gap * [@children.size - 1, 0].max
      fixed = @children.sum {_1.flex?(@dir) ? 0 : _1.natural(@dir, cross)}
      wsum  = @children.sum {_1.weight @dir}
      left  = [main - fixed - gaps, 0].max
      cur   = @dir == :h ? x : y

      @children.each do |c|
        size  = c.flex?(@dir) ? left.to_f * c.weight(@dir) / wsum : c.natural(@dir, cross)
        csize = c.cross_size @dir, cross, size
        off   =
          case c.align || align || :start
          when :center then (cross - csize) / 2
          when :end    then  cross - csize
          else              0
          end
        if @dir == :h
          c.place__ cur, y + off, size, csize
        else
          c.place__ x + off, cur, csize, size
        end
        cur += size + @gap
      end
    end

    def widgets__(list) = @children.each {_1.widgets__ list}

  end# Group


  # @private
  class Stack < Node

    def initialize(**kwargs)
      super
      @children = []
    end

    def add(node) = @children.push(node).then {node}

    def flex?(dir) = spec(dir) == :fill

    def natural(dir, cross)
      s = spec dir
      return s if s.is_a? Numeric
      @children.map {_1.natural dir, cross}.max || 0
    end

    def place__(x, y, w, h)
      @children.each do |c|
        cw     = c.spec(:h).is_a?(Numeric) ? c.spec(:h) : w
        ch     = c.spec(:v).is_a?(Numeric) ? c.spec(:v) : h
        cx, cy = c.at ? [x + c.at[0], y + c.at[1]] : [x, y]
        c.place__ cx, cy, cw, ch
      end
    end

    def widgets__(list) = @children.each {_1.widgets__ list}

  end# Stack


  # @private
  class Grid < Node

    def initialize(columns: nil, rows: nil, gap: 0, **kwargs)
      raise ArgumentError, "specify either 'columns:' or 'rows:'" unless !!columns ^ !!rows
      super(**kwargs)
      @cols, @rows, @gap, @children = columns, rows, gap, []
    end

    def add(node) = @children.push(node).then {node}

    def flex?(dir) = false

    def natural(dir, cross)
      ncols, nrows = dims__
      n, cell      = dir == :h ? [ncols, cell_size__[0]] : [nrows, cell_size__[1]]
      n * cell + @gap * [n - 1, 0].max
    end

    def cross_size(dir, cross, main) = natural(dir == :h ? :v : :h, 0)

    def place__(x, y, w, h)
      cw, ch = cell_size__
      @children.each.with_index do |c, i|
        col, row = @cols ? [i % @cols, i / @cols] : [i / @rows, i % @rows]
        c.place__(
          x + (cw + @gap) * col, y + (ch + @gap) * row,
          c.natural(:h, 0),      c.natural(:v, 0))
      end
    end

    def widgets__(list) = @children.each {_1.widgets__ list}

    private

    def dims__()
      n = @children.size
      @cols ? [@cols, (n / @cols.to_f).ceil] : [(n / @rows.to_f).ceil, @rows]
    end

    def cell_size__()
      [
        @children.map {_1.natural :h, 0}.max || 0,
        @children.map {_1.natural :v, 0}.max || 0
      ]
    end

  end# Grid


  # @private
  class Builder

    def initialize(group, delegate)
      @group, @delegate = group, delegate
    end

    def row(   **kwargs, &block) = group__(Group.new(dir: :h, **kwargs), &block)

    def column(**kwargs, &block) = group__(Group.new(dir: :v, **kwargs), &block)

    def grid(  **kwargs, &block) = group__(Grid.new(**kwargs), &block)

    def stack( **kwargs, &block) = group__(Stack.new(**kwargs), &block)

    def put(widget, **kwargs)    = @group.add Item.new(widget, **kwargs)

    def space(size)              = @group.add FixedSpace.new(size)

    def spacer(weight = 1)       = @group.add Spacer.new(weight)

    def respond_to_missing?(name, include_private = false)
      @delegate.respond_to?(name, true) || super
    end

    def method_missing(name, *args, **kwargs, &block)
      return super unless @delegate.respond_to? name, true
      @delegate.__send__ name, *args, **kwargs, &block
    end

    private

    def group__(group, &block)
      @group.add group
      Builder.new(group, @delegate).instance_exec(&block) if block
      group
    end

  end# Builder

end# Layout
