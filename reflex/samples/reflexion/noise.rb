# -*- coding: utf-8 -*-


%w[xot beeps rays reflex]
  .map  {|s| File.expand_path "../../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflexion/include'


y = 0

draw do
  stroke :white
  line *(0..200).map {|x|
    xx = x * 5
    yy = 200 + Rays.perlin(x / 10.0, y / 100.0) * 100
    [xx, yy]
  }
  y += 1

  text "#{event.fps.to_i} FPS", 10, 10
end
