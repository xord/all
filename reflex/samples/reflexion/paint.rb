# -*- coding: utf-8 -*-


%w[xot beeps rays reflex]
  .map  {|s| File.expand_path "../../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflexion/include'


FILENAME = 'paint.png'

$canvas =
  Image.load(FILENAME) rescue nil ||
  Image.new(512, 512).paint {background :white}


setup do
  size $canvas.size
end

draw do
  image $canvas
end

pointer do
  if down? || drag?
    $canvas.paint do
      fill event.left? ? :red : event.right? ? :blue : :white
      ellipse *(event.pos - 10).to_a, 20, 20
    end
  end
end

key do
  case chars
  when /s/i       then $canvas.save FILENAME
  when /q/i, "\e" then quit
  end
end
