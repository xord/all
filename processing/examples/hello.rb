%w[xot rays reflex processing]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'processing'
using Processing


draw do
  background 0, 10
  textSize 50
  text 'hello, world!', mouseX, mouseY

  x, y = width / 2, height / 2
  x -= 100 if keyIsDown(:gamepad_lstick_left)
  x += 100 if keyIsDown(:gamepad_lstick_right)
  y -= 100 if keyIsDown(:gamepad_lstick_up)
  y += 100 if keyIsDown(:gamepad_lstick_down)
  circle x, y, 100
end

keyPressed do
  p [:pressed, key, keyCode]
end

keyReleased do
  p [:release, key, keyCode]
end
