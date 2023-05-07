%w[xot beeps rays reflex]
  .map  {|s| File.expand_path "../../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflexion/include'


frame = fps = 0


setup do
  size 600, 300
  painter.font = Font.new nil, 24
  interval do
    3.times {put $pos} if $pos
  end
end

draw do
  frame += 1
  fps = event.fps.to_i if (frame % 5) == 0
  text "FRAME: #{frame} | #{fps} FPS", 10, 10
end

key do
  quit if chars == 'q' || code == 53
end

def put (pos)
  window.add View.new {
    position pos
    size     20
    fill     1, rand(0.2..0.7), rand(0.2..0.4)
    shape    EllipseShape.new
    interval do
      self.pos += [rand(-1.0..1.0) * 4, rand(-1.0..0.0) * 8]
    end
    interval do
      self.fill = fill.tap {|f| f.alpha -= 0.02}
      parent.remove self if fill.alpha <= 0
    end
  }
end

pointer do
  $pos = pos
end
