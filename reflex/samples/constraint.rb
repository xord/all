%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


Reflex.start name: "Constraint" do |app|
  Reflex::Window.show title: app.name, frame: [100, 100, 500, 500] do
    gravity 0, 9.8 * meter
    #debug   true

    ball = -> x, y, size_ = 30, color = :red do
      Reflex::View.new {
        pos        x, y
        size       size_
        background color
        dynamic    true
        shape      Reflex::EllipseShape.new(density: 1)
      }
    end

    anchor = -> x, y do
      Reflex::View.new {
        pos        x, y
        size       10
        background :darkgray
        static     true
      }
    end

    # pendulum: snap the hanging ball to the anchor center
    pivot  = add anchor.call(100, 100)
    weight = add ball.call(160, 100, 30, :orange)
    pivot.snap weight

    # motored arm: snap with angle range and a motor
    hinge = add anchor.call(250, 100)
    arm   = add ball.call(250, 140, 20, :peach)
    hinge.snap arm, angle: -60..60, motor: 90

    # ground: a bumpy line the car drives over
    ground = [[0, 480], [70, 465], [140, 482], [210, 462],
              [280, 480], [350, 465], [420, 482], [500, 470]]
    add Reflex::View.new {
      pos 0, 0; size 500, 500
      static true
      shape  Reflex::LineShape.new.tap {|line| line.add_points(*ground.flatten)}
    }

    # car: each wheel rails onto the body with a suspension spring and a
    # drive motor, so it rolls over the bumpy ground
    body   = add Reflex::View.new {
      pos 50, 400; size 70, 16
      background :white
      dynamic    true
      shape      Reflex::RectShape.new(density: 1)
    }
    wheels, axles = [], []
    [14, 56].each do |x|
      wheel = add ball.call(40 + x, 415, 20, :gray)
      wheels << wheel
      axles  << wheel.pin(10, 10).rail(body.pin(x, 20),
        axis: [0, 1], rotate: true, spring: 6, damping: 0.7, motor: 360)
    end

    # reverse the drive each time the car reaches a wall. a wheel or a body
    # corner may touch first, so watch them all; the side check ignores the
    # second touch when two parts hit the same wall together.
    edge      = wall
    mid, side = body.parent.center.x, nil
    reverse   = lambda do |e|
      left = body.center.x < mid
      next if e.view != edge || left == side
      side = left
      axles.each {|a| a.motor = -a.motor}
    end
    [body, *wheels].each {|part| part.on :contact_begin, &reverse}

    # spring chain: balls linked with springs
    # (collide: true lets the nodes bump each other instead of overlapping)
    top  = add anchor.call(400, 50)
    prev = top
    4.times do |i|
      node = add ball.call(400, 90 + i * 40, 20, :green)
      node.link prev, spring: 4, damping: 0.5, collide: true
      prev = node
    end

    # chaser: follows the pendulum weight with a soft spring
    chaser = add ball.call(100, 400, 25, :blue)
    chaser.gravity_scale = 0
    chaser.sensor        = true# do not bump the pendulum
    chaser.chase weight, spring: 2, damping: 1

    # drag any ball with a chase constraint
    drag = nil
    on :pointer do |e|
      case
      when e.down?
        # hit test in each view's local space to respect rotation, and
        # prefer the topmost (= last added) view
        hit = children.to_a.reverse.find do |c|
          next false unless c.dynamic?
          p = c.from_parent e.pos
          p.x.between?(0, c.frame.w) && p.y.between?(0, c.frame.h)
        end
        # grab the view at the clicked point, not at its center
        drag = hit.pin(hit.from_parent e.pos).chase e.pos,
          spring: 5, damping: 0.7 if hit
      when e.drag?
        drag.target = e.pos if drag
      when e.up?
        drag&.remove
        drag = nil
      end
    end

    after :on_draw do |e|
      e.painter.push do
        stroke :gray
        ground.each_cons(2) {|a, b| line a[0], a[1], b[0], b[1]}
        no_stroke
        fill :white
        text "#{e.fps.to_i} FPS - drag a ball to chase the pointer", 10, 10
      end
    end
  end
end
