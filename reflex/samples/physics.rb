%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


Reflex.start name: "Physics" do |app|
  Reflex::Window.show title: app.name, frame: [100, 100, 500, 500] do
    gravity 0, 9.8 * meter
    #debug   true

    add_dynamic = -> x = rand(10..400), y = rand(10..100), size_ = 50 do
      add Reflex::View.new {
        pos        x, y
        size       rand 5..size_
        background [:red, :green, :blue, :yellow, :orange, :pink, :peach].sample
        dynamic    true
        shape      Reflex::EllipseShape.new(density: 1)
      }
    end

    add_static = -> size_ = 50 do
      add Reflex::View.new {
        pos        rand(10..400), rand(200..400)
        size       rand(5..(size_ * 2)), rand(5..size_)
        background :darkgray
        static     true
      }
    end

    50.times {|n| add_dynamic.call}
    5.times  {|n| add_static.call}

    after :draw do |e|
      e.painter.push do
        fill :white
        text "#{e.fps.to_i} FPS", 10, 10
      end
    end

    on :pointer do |e|
      add_dynamic.call *e.pos.to_a if e.down? || e.drag?
    end
  end
end
