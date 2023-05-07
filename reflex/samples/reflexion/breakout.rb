%w[xot beeps rays reflex]
  .map  {|s| File.expand_path "../../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflexion/include'


$hit, $bang = [880, 440].map {|n| Sound.new Oscillator.new(freq: n), 0.1}

def add_shape (klass: RectShape, frame: [0, 0, 100, 100], color: :white, type: :static)
  window.add View.new {
    set frame: frame, background: color, type => true, shape: klass.new(density: 1, friction: 0, restitution: 1)
  }
end

setup do
  set size: [600, 400], friction: 0
  5.times do |y|
    10.times do |x|
      shape = add_shape frame: [(x + 1) * 50, (y + 1) * 20, 30, 10], color: [:white, :red, :green, :blue, :yellow][y]
      shape.on(:contact) {$hit.play; shape.remove_self}
    end
  end
  $bar   = add_shape frame: [0, 350, 100, 20], color: :blue
  bottom = add_shape frame: [0, window.h - 1, window.w, 1]
  bottom.on(:contact) {|e| $bang.play; e.view.remove_self}
end

pointer do |e|
  $bar.x = e.x - $bar.w / 2
  if e.down?
    ball = add_shape klass: [EllipseShape, RectShape].sample, frame: [e.x, $bar.y - 20, 20, 20], type: :dynamic
    ball.velocity = Point.new(rand(-1.0..1.0), -1).normal * 500
  end
end
