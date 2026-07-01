using Reight


class Reight::Overlay

  def initialize(alpha: 0, on_close: nil, &block)
    @backdrop_alpha = alpha
    @close_blocks   = [*on_close]
    world.add_sprite backdrop
    Xot::BlockUtil.instance_eval_or_block_call self, &block if block
  end

  def button(x, y, w, h, **kwargs, &block)
    Reight::Button.new(**kwargs).tap do |b|
      sp                     = b.sprite
      sp.x, sp.y, sp.w, sp.h = x, y, w, h
      b.clicked(&block)
      add_sprite sp
    end
  end

  def add_sprite(sp)
    world.add_sprite sp
  end

  def remove_sprite(sp)
    world.remove_sprite sp
  end

  def show(alpha: nil)
    alpha ||= @backdrop_alpha
    @alpha  = 0
    animate_value(0.2, from: @alpha, to: alpha) {@alpha = _1}
    add_world world
  end

  def close(result = nil)
    world.getContext__&.remove_world world
    @close_blocks.each {_1.call result, self}
    @close_blocks.clear
  end

  def on_close(&block)
    @close_blocks.push block if block
  end

  def draw()
    sprite world
  end

  private

  def world()
    @world ||= SpriteWorld.new
  end

  def backdrop()
    @backdrop ||= RubySketch::Sprite.new(0, 0, 1, 1, physics: false).tap do |sp|
      sp.draw do
        sp.w, sp.h = width, height
        fill 0, @alpha
        no_stroke
        rect 0, 0, sp.w, sp.h
      end
      sp.mouse_clicked {close}
    end
  end

end# Overlay
