# -*- coding: utf-8 -*-


%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


class CheckerWindow < Reflex::Window

  def initialize ()
    super
    set :title,  "Hello Reflex!"
    set :frame, 100, 100, 320, 240
    painter.font = Reflex::Font.new nil, 32
    painter.background = 1
  end

  def on_draw (e)
    p, size, count = e.painter, 10, 16
    count.times do |x|
      count.times do |y|
        next if (x + y) % 2 == 0
        p.fill = x.to_f / count, y.to_f / count, 1
        p.rect x * size, y * size, size - 1, size - 1
      end
    end
  end

end# CheckerWindow


Reflex.start do
  CheckerWindow.new.show
end
