%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


# Shared off-screen canvas. The same Rays::Image is rendered into by
# SourceWindow and sampled as a texture by MirrorWindow. This only works
# because all Reflex windows share a single GL context, so a texture
# allocated in one window is visible to the others.
SIZE   = 300
CANVAS = Rays::Image.new SIZE, SIZE


class SourceWindow < Reflex::Window

  def initialize
    super title: 'source', frame: [80, 80, SIZE + 20, SIZE + 40]
    @t = 0.0
  end

  def on_draw (e)
    @t += 0.04

    CANVAS.paint do |p|
      # fade the previous frame so dots leave fading trails
      p.no_stroke
      p.fill 0, 0, 0, 0.06
      p.rect 0, 0, SIZE, SIZE

      6.times do |i|
        a = @t + i * Math::PI / 3
        r = 110 + Math.sin(@t * 0.6 + i) * 25
        x = SIZE / 2 + Math.cos(a) * r
        y = SIZE / 2 + Math.sin(a) * r
        p.fill (Math.sin(@t + i)       + 1) / 2,
               (Math.sin(@t + i + 2.1) + 1) / 2,
               (Math.sin(@t + i + 4.2) + 1) / 2
        p.ellipse x, y, 16, 16
      end
    end

    e.painter.background 0.1
    e.painter.image CANVAS, 10, 10
  end

  def on_update (e) = redraw

end# SourceWindow


class MirrorWindow < Reflex::Window

  TILE   = SIZE / 2
  SCALES = [[1.0, 1.0], [1.0, 0.5], [0.5, 1.0], [0.5, 0.5]]

  def initialize
    super title: 'mirror', frame: [420, 80, TILE * 2 + 20, TILE * 2 + 40]
  end

  def on_draw (e)
    p = e.painter
    p.background 0
    4.times do |i|
      row, col = i / 2, i % 2
      sx, sy   = SCALES[i]
      p.image CANVAS, col * TILE, row * TILE, TILE * sx, TILE * sy
    end
  end

  def on_update (e) = redraw

end# MirrorWindow


Reflex.start do
  SourceWindow.new.show
  MirrorWindow.new.show
end
