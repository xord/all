# -*- coding: utf-8 -*-


%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


module DisplayFPS

  def fps ()
    @fps       ||= 0
    @fps_count ||= 0
    now = Time.now
    @fps = 1.0 / (now - @fps_prev) if
      @fps_prev && @fps_prev < now && (@fps_count += 1) % 32 == 1
    @fps_prev = now
    @fps.to_i
  end

  def draw_fps (p, x = 0, y = 0)
    fill = p.fill
=begin
    p.fill = 1
    (-1..1).each do |xx|
      (-1..1).each do |yy|
        p.text fps, x + xx, y + yy, @fps_font
      end
    end
=end
    p.fill = 0
    p.text "#{fps} FPS", x, y, @fps_font ||= Reflex::Font.new(nil, 20)
    p.fill = fill
  end

end# DisplayFPS


class Ring

  def initialize (x, y, width, height, colors, rotation = 1)
    @x, @y, @width, @height, @colors, @rot, @angle, @min =
     x, y, width, height, colors, rotation, 0, 0
  end

  def on_draw (p)
    w = 45
    p.fill = *@colors[0]
    fin p, 0,   w
    fin p, 180, w
    p.fill = *@colors[1]
    fin p, 90,  w
    fin p, 270, w
  end

  def on_update (dt)
    @angle = (@angle + @rot) % 360
  end

  def fin (p, angle, width)
    angle += @angle
    p.ellipse @x, @y, @width, @height, from: angle, to: angle + width, hole: @min
  end

end# Ring


class ShapesWindow < Reflex::Window

  include Enumerable
  include DisplayFPS

  def initialize ()
    super
    set :title,  "Shapes Sample"
    set :frame, 100, 400, 640, 240
    painter.background = 1
    @rings = []
    setup
  end

  def setup ()
    c = [0.9, 0.5, 0.5], [0.5, 0.5, 0.9]
    w = 100
    h = 100
    rot = 0
    (0..5).each do |y|
      (0..10).each do |x|
        @rings << Ring.new(x * w, y * h, w, h, c, rot += 0.1)
      end
    end
  end

  def on_draw (e)
    each {|o| o.on_draw e.painter}
  end

  def on_update (dt)
    each {|o| o.on_update dt}
    redraw
    @count ||= 0
    fps_ = fps
    #puts "#{fps_} FPS, GC count: #{GC.stat[:count]}" if (@count += 1) % 100 == 0
  end

  def on_key_down (key)
    close if key.code == 53 || key.chars =~ /q/i
  end

  def each ()
    @rings.each {|o| yield o}
  end

end# ShapesWindow


Reflex.start name: "Shapes" do
  ShapesWindow.new.show
end
