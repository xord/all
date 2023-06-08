%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


class HelloWindow < Reflex::Window

  def initialize ()
    super title: "Hello Reflex!", frame: [100, 100, 320, 240]
    p = painter
    p.font Reflex::Font.new "Menlo", 32
    p.background 0
    p.fill 1
  end

  def on_draw (e)
    p = e.painter
    draw_grid p
    p.text "hello world!", 5, 5
  end

  def on_update (e)
    painter.background = rand, rand, rand
    redraw
  end

  def on_pointer(e)
    p e
    p e.prev
    p e.down
  end

  def draw_grid (painter)
    painter.push do |p|
      w, h = frame.size.to_a
      p.stroke 0.5, 0.4
      (0..w).step(5).each {|x| p.line x, 0, x, h}
      (0..h).step(5).each {|y| p.line 0, y, w, y}
    end
  end

end# HelloWindow


Reflex.start do
  HelloWindow.new.show
end
