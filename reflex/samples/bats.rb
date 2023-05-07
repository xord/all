%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


win = Reflex::Window.new do
  set title: "Bats", frame: [100, 100, 300, 300]

  @children = []
  @count    = model = Reflex::Model.new(@children.size) {set min: 0}

  def update_count ()
    @count.data = @children.size
  end

  def spawn (x, y)
    name = "bat_#{@count.data}"
    @children.push add Reflex::View.new {
      size = 16
      set name: name, frame: [x - size, y - size, size * 2, size * 2]

      angle = 0
      speed = (rand * 2 - 1) * 30

      on :update do
        move_by rand(5) - 2, rand(5) - 2
        angle += speed
        angle %= 360
        redraw
      end

      c = [rand, rand, rand]
      on :draw do |e|
        p, b = e.painter, e.bounds
        p.fill *c
        #p.rect b
        p.ellipse b, from: angle,       to: angle + 90
        p.ellipse b, from: angle + 180, to: angle + 270
      end
    }
    update_count
  end

  on :key_down do |e|
    case e.code
    when 53 then close
    end

    case e.chars
    when 'g'
      GC.start
      puts 'GC!'
    when 'x'
      remove @children.shift unless @children.empty?
      update_count
    end
  end

  on :pointer do |e|
    case e.action
    when :down
      spawn e.x, e.y
      @spawning = true
    when :up
      @spawning = false
    when :move
      spawn e.x, e.y if @spawning
    end
  end

  add Reflex::TextView.new {
    set name: :count, pos: [10, 10], model: model
  }

  root.on :draw do |e|
    p = e.painter
    p.fill 1
    p.text "draw on root view. (#{e.fps.to_i} FPS)", 10, 30
  end

  #100.times {spawn *frame.move_to(0).center.to_a}
end


Reflex.start do
  win.show
end
