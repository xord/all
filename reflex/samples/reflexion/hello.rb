# -*- coding: utf-8 -*-


%w[xot beeps rays reflex]
  .map  {|s| File.expand_path "../../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflexion/include'


gray  = 0
array = []

draw do
  gray += 0.01
  gray %= 1
  background gray
  array.unshift event.fps
  array.slice! 32..-1
  text "#{array.reduce(0) {|sum, n| sum + n}.tap {|n| break n / array.size}.to_i} FPS", 10, 30
  text "#{event.fps} FPS", 10, 10
end
