class Reight::SpriteEditor::AnimImageList

  C       = Reight::CONTEXT__
  PADDING = 1

  include Reight::Hookable

  def initialize()
    hook :selected
    hook :add_image

    self.anim = nil
  end

  def anim=(anim)
    return if anim == @anim
    @anim = anim
    select @anim&.at 0
  end

  def select(image)
    return if image == @image
    @image = image
    selected! @image
  end

  def draw()
    sp = sprite
    C.clip sp.x, sp.y, sp.w, sp.h

    image_frames.each do |image, x, y, w, h|
      if image
        C.blend image, 0, 0, image.w, image.h, x, y, w, h, REPLACE
      else
        inside = @mouse_entered &&
          (x..(x + w)).include?(sp.mouse_x) &&
          (y..(y + h)).include?(sp.mouse_y)
        C.fill inside ? 220 : 190
        C.no_stroke
        C.rect x, y, w, h
        if inside
          C.text_align CENTER, CENTER
          C.text_size 20
          C.fill 190
          C.text "+", x, y - 3, w, h
        end
      end
      if image && image == @image
        C.no_fill
        C.stroke 255
        C.rect x, y, w + 1, h + 1
      end
    end
  end

  def mouse_moved(x, y)
    mouse_entered x, y unless @mouse_entered
    check_mouse_leave
  end

  def mouse_entered(x, y)
    @mouse_entered = true
  end

  def mouse_leaved(x, y)
    @mouse_entered = false
  end

  def check_mouse_leave()
    sp = sprite
    C.set_timeout 0.1, id: "#{__method__}_#{sp.object_id}" do
      x, y = C.mouse_x - sp.x, C.mouse_y - sp.y
      if x < 0 || sp.w <= x || y < 0 || sp.h <= y
        mouse_leaved x, y
      else
        check_mouse_leave
      end
    end
  end

  def mouse_clicked(x, y)
    index, image, = image_frames
      .map.with_index {|a, i| [i, *a]}
      .find {|i, _, xx, yy, w, h| (xx..(xx + w)).include?(x) && (yy..(yy + h)).include?(y)}
    if image
      selected! image
    else
      add_image! index
    end
  end

  def sprite()
    @sprite ||= RubySketch::Sprite.new.tap do |sp|
      sp.draw           {draw}
      #sp.mouse_pressed  {mouse_pressed  sp.mouse_x, sp.mouse_y}
      #sp.mouse_released {mouse_released sp.mouse_x, sp.mouse_y}
      sp.mouse_moved    {mouse_moved    sp.mouse_x, sp.mouse_y}
      #sp.mouse_dragged  {mouse_dragged  sp.mouse_x, sp.mouse_y}
      sp.mouse_clicked  {mouse_clicked  sp.mouse_x, sp.mouse_y}
    end
  end

  private

  def image_frames()
    return [] unless @anim
    w = h = sprite.h - PADDING * 2
    images  = @anim.to_a
    least   = (sprite.w / sprite.h.to_f).ceil
    images += [nil] * (least - @anim.size) if least > @anim.size
    images.map.with_index do |image, index|
      [image, PADDING + (w + PADDING) * index, PADDING, w, h]
    end
  end
=begin
  def initialize(
    app, chips, size = 8,
    page_width  = app.project.chips_page_width,
    page_height = app.project.chips_page_height)

    hook :frame_changed
    hook :offset_changed

    @app, @chips = app, chips
    @page_size   = create_vector page_width, page_height
    @offset      = create_vector 0, 0

    set_frame 0, 0, size, size
  end

  attr_reader :x, :y, :size, :offset

  def chip = @chips.at x, y, size, size

  def set_frame(x, y, w = size, h = size)
    raise 'Chips: width != height' if w != h
    @x    = align_to_grid(x).clamp(0..@chips.image.width)
    @y    = align_to_grid(y).clamp(0..@chips.image.height)
    @size = w
    frame_changed! @x, @y, @size, @size
  end

  def offset=(pos)
    sp      = sprite
    x       = pos.x.clamp([-(@chips.image.width  - sp.w), 0].min..0)
    y       = pos.y.clamp([-(@chips.image.height - sp.h), 0].min..0)
    offset  = create_vector x, y
    return if offset == @offset
    @offset = offset
    offset_changed! @offset
  end

  def index2offset(index)
    pw, ph = @page_size.x.to_i, @page_size.y.to_i
    size   = @chips.image.width / pw
    create_vector(-(index % size).to_i * pw, -(index / size).to_i * ph)
  end

  def offset2index(offset = self.offset)
    iw     = @chips.image.width
    pw, ph = @page_size.x.to_i, @page_size.y.to_i
    x, y   = (-offset.x / ph).to_i, (-offset.y / pw).to_i
    w      = (iw / pw).to_i
    y * w + x
  end

  def draw()
    sp = sprite
    clip sp.x, sp.y, sp.w, sp.h

    fill 0
    no_stroke
    rect 0, 0, sp.w, sp.h

    translate offset.x, offset.y
    draw_offset_grids
    image @chips.image, 0, 0
    draw_frame
  end

  def draw_offset_grids()
    no_fill
    stroke 50
    iw, ih = @chips.image.width, @chips.image.height
    cw, ch = @page_size.x, @page_size.y
    (cw...iw).step(cw) {|x| line x, 0, x,  ih}
    (ch...ih).step(ch) {|y| line 0, y, iw, y}
  end

  def draw_frame()
    no_fill
    stroke 255
    stroke_weight 1
    rect @x, @y, @size, @size
  end

  def mouse_pressed(x, y)
    @prev_pos = create_vector x, y
  end

  def mouse_released(x, y)
  end

  def mouse_dragged(x, y)
    pos          = create_vector x, y
    self.offset += pos - @prev_pos if @prev_pos
    @prev_pos    = pos
  end

  def mouse_clicked(x, y)
    set_frame(
      -offset.x + align_to_grid(x),
      -offset.y + align_to_grid(y))
  end

  def sprite()
    @sprite ||= RubySketch::Sprite.new.tap do |sp|
      sp.draw           {draw}
      sp.mouse_pressed  {mouse_pressed  sp.mouse_x, sp.mouse_y}
      sp.mouse_released {mouse_released sp.mouse_x, sp.mouse_y}
      sp.mouse_dragged  {mouse_dragged  sp.mouse_x, sp.mouse_y}
      sp.mouse_clicked  {mouse_clicked  sp.mouse_x, sp.mouse_y}
    end
  end

  private

  def align_to_grid(n)
    n.to_i / 8 * 8
  end
=end
end# AnimImageList
