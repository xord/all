%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


$text = $pos = ''


w = Reflex::Window.new
w.title = "Reflex Input Sample"
w.frame = 100, 100, 800, 300
w.painter.font = Reflex::Font.new nil, 32

w.on :draw do |e|
  p = e.painter
  p.fill = 1
  p.text $text, 100, 100
  p.text $pos, 100, 150
end

w.on :key_down do |key|
  $text += key.chars
  $text = $text[-10..-1] if $text.size > 10
  p [key.chars, key.code, key.repeat, key.modifiers]
  w.redraw
  w.close if key.code == 53
end

w.on :pointer_move do |points|
  $pos = "#{points.x}, #{points.y}"
  p [points.action, points.x, points.y, points.size, points.modifiers, points.count, points.drag?]
  w.redraw
end

Reflex.start do
  w.show
end
