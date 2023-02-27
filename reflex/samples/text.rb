# -*- coding: utf-8 -*-


%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


lines = File.readlines(__FILE__)


win = Reflex::Window.new do
  set title: "Rays/Reflex Text Test", frame: [100, 100, 600, 400]
  painter.background 0.1
  painter.font Reflex::Font.new 'Menlo', 12
  on :draw do |e|
    e.painter.push do
      linenum       = "%5d "
      linenum_width = font.width(linenum % 0).ceil
      line_height   = (font.height * 1.0).ceil

      fill 0.3
      rect 0, 0, linenum_width, 10000

      fill 1 #rand, rand, rand, 1
      lines.each.with_index do |line, i|
        text "#{linenum % i} #{line.chomp}"
        translate 0, line_height
      end
    end
  end
end


Reflex.start do
  win.show
end
