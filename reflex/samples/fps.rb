# -*- coding: utf-8 -*-


%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


x = 0
y = 0
font = Reflex::Font.new "Osaka", 32
prev = Time.now
fps = 0

w = Reflex::Window
  .new(:title => "Reflex on Ruby", :frame => [100, 100, 600, 400])
  .before(:close) {w.hide; sleep 1; w.show; sleep 1}
  .on(:move) {|x, y| p [x, y]}
  .on(:resize) {|w, h| p [w, h]}
  .on(:update) {w.redraw}
  .on(:draw) do |e|
    p, sz = e.painter, w.frame.size
    p.fill = 1, 0.5, 0.5, 0.05
    #p.stroke = 0.5, 0.5, 1
    100.times do
      n = rand * Math::PI * 2
      xx = x + Math.sin(n) * 50
      yy = y + Math.cos(n) * 50
      p.rect xx, yy, 50, 50
    end

    p.font font

    p.fill = 1
    p.text "hello Rays/Reflex!", x, y + 32
    x = (x + 1) % 100
    y = (y + 1) % 100

    now = Time.now
    fps = 1 / (now - prev) if x % 10 == 0
    p.fill = 1, 1, 1, 1
    p.text "#{fps.to_i} FPS", 0, sz.y - font.height
    prev = now
  end

Reflex.start do
  w.show
end
