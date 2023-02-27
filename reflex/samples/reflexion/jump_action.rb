# -*- coding: utf-8 -*-


%w[xot beeps rays reflex]
  .map  {|s| File.expand_path "../../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflexion/include'


$player   =
$ground   = nil
$score    = 0
$gameover = false
$left     =
$right    = false

class View
  alias center_noangle center
  def center
    p, c, a = pos, center_noangle, angle
    a == 0 ? c : p + (c - p).rotate(a)
  end
end

class KeyEvent
  def left? ()
    code == 123
  end
  def right? ()
    code == 124
  end
  def space? ()
    code == 49
  end
end

setup do
  size 640, 320
  flow :none
  gravity 0, 9.8 * meter

  root.wall.clear_fixtures
  add_ground
  add_bricks
  add_coins
  add_enemies
  add_player
end

def add_ground ()
  $ground = window.add View.new {
    width 10000
    height parent.height
    static true
  }

  w, h = $ground.width, $ground.height
  edges = (0..w).step(5).map {|x|
    [x, h + Rays.perlin(x / 100.0, 0) * 30 - 50]
  }
  edges = [[0, 0]] + edges + [[w, 0]]

  $ground.body.clear_fixtures
  $ground.body.add_edge *edges
  $ground.on :draw do |e|
    e.painter.push fill: nil, stroke: :white do
      lines *edges
    end
  end
end

def add_bricks ()
  range = place_range
  50.times do
    window.add RectShape.new {
      pos rand(range), 200
      size *(0..1).map {rand(20..100)}
      fill rand, rand, rand
      dynamic true
      density 1
    }
  end
end

def add_coins ()
  range = place_range
  50.times do
    window.add EllipseShape.new {
      pos rand(range), 100
      size 30
      fill :yellow
      static true
      sensor true
      on :contact do
        remove_self
        $score += 1
      end
    }
  end
end

def add_enemies ()
  range = place_range
  10.times do
    window.add RectShape.new {
      pos rand(range), 200
      size 50
      fill :red
      static true
      sensor true
      on :contact do |e|
        $gameover = true if e.view == $player
      end
    }
  end
end

def place_range ()
  $ground.frame.inset_by(100).tap {|f| break f.left .. f.right}
end

def add_player ()
  $player = window.add EllipseShape.new {
    @jump_count = 0

    pos 50, 50
    size 30
    dynamic true
    density 1
    friction 1

    player_image = Image.new(*size.to_a).paint do |p|
      step, colors = 5, [:green, :blue]
      (0..height).step step do |y|
        (0..width).step step do |x|
          p.fill colors[(x + y) % 2]
          p.rect x, y, step, step
        end
      end
    end

    def self.jumpable? ()
      @jump_count <= 1
    end
    def self.jump ()
      return unless jumpable?
      velocity velocity.tap {|v| v.y = -5 * meter}
      @jump_count += 1
    end

    on :update do
      dir = 0
      dir -= 1 if $left
      dir += 1 if $right
      self.angular_velocity = 360 * 3 * dir
    end
    on :draw do |e|
      e.painter.push fill: :white do
        image player_image
      end
    end
    on :contact_begin do
      @jump_count = 0
    end
  }
end

update do
  old_x, new_x = window.root.scroll.x, $player.center.x - window.width / 2
  window.root.scroll_to (old_x + new_x) / 2, 0
end

draw do
  fill :white
  font nil, 30
  text "SCORE: #{$score}", 10, 10
  text "#{event.fps.to_i} FPS", 10, 50
  if $gameover
    fill :red
    font nil, 100
    text "GAMEOVER!", 100, 100
  end
end

key do
  next unless down? || up?
  $left  = down? if left?
  $right = down? if right?
  $player.jump   if space? && down?
end
