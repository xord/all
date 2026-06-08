using Reight


# @private
class Reight::SpriteEditor::Canvas

  extend  Reight::Hookable
  extend  Reight::HasState
  include Reight::Widget

  state :image

  hook :canvas_pressed
  hook :canvas_released
  hook :canvas_moved
  hook :canvas_dragged
  hook :canvas_clicked

  attr_accessor :selection

  alias set_image__ image=

  def image=(...)
    set_image__(...)
    @grids = nil
  end

  protected

  def draw(sp)
    clip sp.x, sp.y, sp.w, sp.h
    fill 0
    no_stroke
    rect 0, 0, sp.w, sp.h
    return unless @image

    sx, sy = sp.w / @image.w, sp.h / @image.h
    no_fill
    stroke_weight 0

    push do
      scale sx, sy
      draw_grids__
    end

    copy @image, 0, 0, @image.w, @image.h, 0, 0, sp.w, sp.h if @image

    push do
      scale sx, sy
      draw_selection__ sx, sy
    end
  end

  def mouse_pressed(x, y, button)
    canvas_pressed! x, y, button if @image
  end

  def mouse_released(x, y, button)
    canvas_released! x, y, button if @image
  end

  def mouse_moved(x, y)
    super
    canvas_moved! x, y if @image
  end

  def mouse_dragged(x, y, button)
    canvas_dragged! x, y, button if @image
  end

  def mouse_clicked(x, y, button)
    canvas_clicked! x, y, button if @image
  end

  def to_widget(x, y)
    sp = sprite
    return x * (@image.w.to_f / sp.w), y * (@image.h.to_f / sp.h)
  end

  private

  def draw_grids__()
    push do
      stroke 50, 50, 50
      shape grid__ 8
      stroke 100, 100, 100
      shape grid__ 16
      stroke 150, 150, 150
      shape grid__ 32
    end
  end

  def grid__(interval)
    (@grids ||= {})[interval] ||= create_shape.tap do |sh|
      w, h = @image.w, @image.h
      sh.begin_shape LINES
      (0..w).step(interval).each do |x|
        sh.vertex x, 0
        sh.vertex x, h
      end
      (0..h).step(interval).each do |y|
        sh.vertex 0, y
        sh.vertex w, y
      end
      sh.end_shape
    end
  end

  def draw_selection__(scale_x, scale_y)
    return unless @selection&.size == 4
    push do
      no_fill
      stroke 255, 255, 255
      shader selection_shader__.tap {|sh|
        sh.set :time, frame_count.to_f / 60
        sh.set :scale, scale_x, scale_y
      }
      rect(*@selection)
    end
  end

  def selection_shader__()
    @selection_shader ||= create_shader nil, <<~END
      varying vec4  vertTexCoord;
      uniform float time;
      uniform vec2  scale;
      void main()
      {
        vec2 pos = vertTexCoord.xy * scale;
        float t  = floor(time * 4.) / 4.;
        float x  = mod( pos.x + time, 4.) < 2. ? 1. : 0.;
        float y  = mod(-pos.y + time, 4.) < 2. ? 1. : 0.;
        gl_FragColor = x != y ? vec4(0., 0., 0., 1.) : vec4(1., 1., 1., 1.);
      }
    END
  end

end# Canvas
