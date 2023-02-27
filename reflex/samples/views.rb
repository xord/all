# -*- coding: utf-8 -*-


%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'

include Reflex


win = Window.new do
  images = [:red, :blue].map do |col|
    Image.new(32, 32).tap do |img|
      img.paint do
        fill :white
        rect img.bounds
        fill col
        ellipse img.bounds.inset_by(2, 2)
      end
    end
  end

  add text   = TextView.new  {set name: :text,   data: 'Text View'}
  add image1 = ImageView.new {set name: :image,  data: images.first}
  add image2 = ImageView.new {set name: :image,  model: image1.model}
  add button = Button.new    {set name: :button, text: 'push me!'}

  count = 0
  button.on :press do |e|
    count += 1
    image1.image = images[count % 2]
  end

  set title: 'Many View Sample', frame: [100, 100, 500, 400], flow: :right
end


Reflex.start do
  win.show
end
