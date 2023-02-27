# -*- coding: utf-8 -*-


%w[xot beeps rays reflex]
  .map  {|s| File.expand_path "../../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflexion/include'


COLORS = [:red, :green, :blue, :orange, :yellow, :indigo, :pink, :peach, :brown]

count = 0

setup do
  size    600, 400
  gravity 0, 9.8 * meter
end

draw do
  text "#{event.fps.to_i} FPS | #{count} BLOCKS", 10, 10
end

pointer do
  if down? || drag?
    count += 1 if window.add View.new {
      pos        event.pos
      size       rand 20..40
      background event.right? ? :gray : COLORS.sample
      dynamic    event.left?
      shape      [RectShape, EllipseShape].sample.new(density: 1)
      interval(1) {fill rand, rand, rand}
    }
  end
end
