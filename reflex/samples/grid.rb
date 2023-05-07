%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


win = Reflex::Window.new do
  set title: "Grid Test", frame: [100, 100, 50, 50]
  painter.background 0

  on :draw do |e|
    p = e.painter
    p.push

    w, h = frame.size.to_a

    p.fill 1, 0, 0

    p.rect 1, 1, 5, 5

    p.stroke 0.3, 0.4
    (0..frame.width) .step(2).each {|x| p.line x, 0, x, h}
    (0..frame.height).step(2).each {|y| p.line 0, y, w, y}
    p.stroke 0.5, 0.4
    (0..frame.width) .step(10).each {|x| p.line x, 0, x, h}
    (0..frame.height).step(10).each {|y| p.line 0, y, w, y}

    p.translate 3, 10, 0
    p.fill nil
    p.stroke 1

    p.line 0, 0, 5, 0

    p.translate 0, 10, 0

    p.rect 0, 0, 5, 5

    p.translate 0, 10, 0
    p.fill 0.5, 0.5, 1
    p.stroke nil

    p.rect 0, 0, 5, 5

    p.translate 0, 10, 0
    p.fill 0.5, 0.5, 1
    p.stroke 0.5, 1, 0.5

    p.rect 0, 0, 5, 5

    p.pop
  end
end


Reflex.start do
  win.show
end
