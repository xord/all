# -*- coding: utf-8 -*-


%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


Reflex::Window.new do
  title 'Shape Sample'
  frame 100, 100, 800, 500

  def on_draw (e)
    e.painter.push do
      fill :pink
      stroke 1
      stroke_width 2

      x, y, y2, w, h = 10, 10, 100, 50, 50

      push do
        rect                       x, y,  w, h
        polygon Rays::Polygon.rect x, y2, w, h

        translate 100, 0
        rect                       x, y,  w, h, 5
        polygon Rays::Polygon.rect x, y2, w, h, 5

        translate 100, 0
        rect                       x, y,  w, h, 5, 10, 15, 20
        polygon Rays::Polygon.rect x, y2, w, h, 5, 10, 15, 20

        translate 100, 0
        ellipse                       x, y,  w, h
        polygon Rays::Polygon.ellipse x, y2, w, h

        translate 100, 0
        ellipse                       x, y,  w, h, from: 45, to: 180
        polygon Rays::Polygon.ellipse x, y2, w, h, from: 45, to: 180

        translate 100, 0
        ellipse                       x, y,  w, h, hole: 10
        polygon Rays::Polygon.ellipse x, y2, w, h, hole: 10

        translate 100, 0
        ellipse                       x, y,  w, h, hole: 10, from: 200, to: 300
        polygon Rays::Polygon.ellipse x, y2, w, h, hole: 10, from: 200, to: 300

        translate 100, 0
        curve                       x, y,  x + w, y,  x + w, y  + h, x, y  + h
        polygon Rays::Polygon.curve x, y2, x + w, y2, x + w, y2 + h, x, y2 + h

        translate 100, 0
        curve                       x, y,  x + w, y,  x + w, y  + h, x, y  + h, loop: true
        polygon Rays::Polygon.curve x, y2, x + w, y2, x + w, y2 + h, x, y2 + h, loop: true

        translate 100, 0
        bezier                       x, y,  x + w, y,  x + w, y  + h, x, y  + h
        polygon Rays::Polygon.bezier x, y2, x + w, y2, x + w, y2 + h, x, y2 + h

        translate 100, 0
        bezier                       x, y,  x + w, y,  x + w, y  + h, x, y  + h, loop: true
        polygon Rays::Polygon.bezier x, y2, x + w, y2, x + w, y2 + h, x, y2 + h, loop: true
      end

      translate 0, 200
      push do
        line                    x, y,  x + w, y  + h
        line Rays::Polyline.new x, y2, x + w, y2 + h

        translate 100, 0
        line                    x, y,  x + w, y  + h, x, y  + h
        line Rays::Polyline.new x, y2, x + w, y2 + h, x, y2 + h

        translate 100, 0
        line                    x, y,  x + w, y  + h, x, y  + h, loop: true
        line Rays::Polyline.new x, y2, x + w, y2 + h, x, y2 + h, loop: true

        translate 100, 0
        polygon Rays::Polyline.new(x, y, x + w, y + h).expand 10

        translate 100, 0
        polygon Rays::Polyline.new(x, y, x + w, y + h, x, y + h).expand 10

        translate 100, 0
        polygon Rays::Polyline.new(x, y, x + w, y + h, x, y + h, loop: true).expand 10
      end
    end
  end
end.show


Reflex.start
