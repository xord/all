%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'

include Reflex


win = Window.new do
  image = Image.new(32, 32).tap do |img|
    img.paint do
      fill :white
      rect img.bounds
      fill :red
      ellipse img.bounds.inset_by(2, 2)
    end
  end

  256.times do
    add ImageView.new {set data: image}
  end

  on :update do
    redraw
  end

  after :draw do |e|
    e.painter.push fill: :black do
      rect 0, 0, 100, 40
      fill :white
      text "#{e.fps.to_i} FPS", 10, 10
    end
  end

  title 'Many Image Views'
  frame 100, 100, 500, 400
end


Reflex.start do
  win.show
end
