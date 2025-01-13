using Reight


class Reight::SpriteEditor < Reight::App

  def canvas()
    @canvas ||= Canvas.new(
      self,
      project.chips_image,
      project.chips_image_path
    ).tap do |canvas|
      canvas. tool_changed {update_active_tool}
      canvas.color_changed {update_active_color}
    end
  end

  def activated()
    super
    history.disable do
      colors[7].click
      tools[1].click
      chip_sizes[0].click
      brush_sizes[0].click
    end
  end

  def draw()
    background 200
    sprite(*sprites)
    super
  end

  def key_pressed()
    super
    shift, ctrl, cmd = %i[shift control command].map {pressing? _1}
    ch               = chips
    case key_code
    when LEFT  then ch.set_frame ch.x - ch.size, ch.y, ch.size, ch.size
    when RIGHT then ch.set_frame ch.x + ch.size, ch.y, ch.size, ch.size
    when UP    then ch.set_frame ch.x, ch.y - ch.size, ch.size, ch.size
    when DOWN  then ch.set_frame ch.x, ch.y + ch.size, ch.size, ch.size
    when :c    then copy  if ctrl || cmd
    when :x    then cut   if ctrl || cmd
    when :v    then paste if ctrl || cmd
    when :z    then shift ? self.redo : undo if ctrl || cmd
    when :s    then select.click
    when :b    then  brush.click
    when :l    then   line.click
    when :f    then   fill.click
    when :r    then (shift ? fill_rect    : stroke_rect   ).click
    when :e    then (shift ? fill_ellipse : stroke_ellipse).click
    end
  end

  def window_resized()
    super
    [colors, tools, chip_sizes, brush_sizes].flatten.map(&:sprite)
      .each {|sp| sp.w = sp.h = BUTTON_SIZE}

    chips.sprite.tap do |sp|
      sp.x      = SPACE
      sp.y      = NAVIGATOR_HEIGHT + SPACE
      sp.w      = CHIPS_WIDTH
      sp.bottom = height - SPACE
    end
    colors.map {_1.sprite}.each.with_index do |sp, index|
      sp.x = chips.sprite.right + SPACE + sp.w * (index % 4)
      sp.y = height - (SPACE + sp.h * (4 - index / 4))
    end
    tools.map {_1.sprite}.each.with_index do |sp, index|
      line   = index < 3 ? 0 : 1
      index -= 3 if line == 1
      sp.x   = colors.last.sprite.right + SPACE + (sp.w + 1) * index
      sp.y   = colors.first.sprite.y + (sp.h + 1) * line
    end
    canvas.sprite.tap do |sp|
      sp.x      = chips.sprite.right + SPACE
      sp.y      = chips.sprite.y
      sp.bottom = colors.first.sprite.top - SPACE
      sp.w      = sp.h
    end
    chip_sizes.map {_1.sprite}.each.with_index do |sp, index|
      sp.x = canvas.sprite.right + SPACE + (sp.w + 1) * index
      sp.y = canvas.sprite.y
    end
    brush_sizes.map {_1.sprite}.each.with_index do |sp, index|
      sp.x = chip_sizes.first.sprite.x + (sp.w + 1) * index
      sp.y = chip_sizes.last.sprite.bottom + SPACE
    end
    shapes.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = 30
      sp.h = BUTTON_SIZE
      sp.x = brush_sizes.first.sprite.x + (sp.w + 1) * index
      sp.y = brush_sizes.last.sprite.bottom + SPACE
    end
    types.map {_1.sprite}.each.with_index do |sp, index|
      sp.w = 50
      sp.h = BUTTON_SIZE
      sp.x = shapes.first.sprite.x + (sp.w + 1) * index
      sp.y = shapes.last.sprite.bottom + SPACE
    end
  end

  def undo(flash: true)
    history.undo do |action|
      case action
      in [:frame, [x, y, w, h], _]   then chips.set_frame x, y, w, h
      in [:capture, before, _, x, y] then canvas.apply_frame before, x, y
      in [  :select, sel, _]         then sel ? canvas.select(*sel) : canvas.deselect
      in [:deselect, sel]            then       canvas.select(*sel)
      end
      self.flash 'Undo!' if flash
    end
  end

  def redo(flash: true)
    history.redo do |action|
      case action
      in [:frame, _, [x, y, w, h]]  then chips.set_frame x, y, w, h
      in [:capture, _, after, x, y] then canvas.apply_frame after, x, y
      in [  :select, _, sel]        then canvas.select(*sel)
      in [:deselect, _]             then canvas.deselect
      end
      self.flash 'Redo!' if flash
    end
  end

  def cut(flash: true)
    copy flash: false
    image, x, y = @copy || return
    canvas.begin_editing do
      clear_canvas x, y, image.width, image.height
    end
    self.flash 'Cut!' if flash
  end

  def copy(flash: true)
    sel   = canvas.selection || canvas.frame
    image = canvas.capture_frame(sel) || return
    x, y, = sel
    @copy = [image, x - canvas.x, y - canvas.y]
    self.flash 'Copy!' if flash
  end

  def paste(flash: true)
    image, x, y = @copy || return
    w, h        = image.width, image.height
    history.group do
      canvas.deselect
      canvas.begin_editing do
        canvas.paint do |g|
          g.copy image, 0, 0, w, h, x, y, w, h
        end
      end
      canvas.select canvas.x + x, canvas.y + y, w, h
    end
    self.flash 'Paste!' if flash
  end

  def can_cut?   = true
  def can_copy?  = true
  def can_paste? = @copy

  def clear_canvas(x, y, w, h)
    canvas.clear [x, y, w, h], color: colors.first.color
  end

  private

  def sprites()
    [canvas, chips, *chip_sizes, *colors, *tools, *brush_sizes, *shapes, *types]
      .map(&:sprite) + super
  end

  def chips()
    @chips ||= Chips.new self, project.chips_image do |x, y, w, h|
      canvas.set_frame x, y, w, h
      chip_changed x, y, w, h
    end
  end

  def chip_sizes()
    @chip_sizes ||= group(*[8, 16, 32].map {|size|
      Reight::Button.new name: "#{size}x#{size}", label: size do
        chips.set_frame chips.x, chips.y, size, size
      end
    })
  end

  def tools()
    @tools ||= group(
      select,
      brush,
      fill,
      stroke_line,
      stroke_rect,
        fill_rect,
      stroke_ellipse,
        fill_ellipse
    )
  end

  def select         = @select         ||= Select.new(self)                 {canvas.tool = _1}
  def brush          = @brush          ||= Brush.new(self)                  {canvas.tool = _1}
  def fill           = @fill           ||= Fill.new(self)                   {canvas.tool = _1}
  def stroke_line    = @stroke_line    ||= Line.new(self)                   {canvas.tool = _1}
  def stroke_rect    = @stroke_rect    ||= Shape.new(self, :rect,    false) {canvas.tool = _1}
  def   fill_rect    =   @fill_rect    ||= Shape.new(self, :rect,    true)  {canvas.tool = _1}
  def stroke_ellipse = @stroke_ellipse ||= Shape.new(self, :ellipse, false) {canvas.tool = _1}
  def   fill_ellipse =   @fill_ellipse ||= Shape.new(self, :ellipse, true)  {canvas.tool = _1}

  def brush_sizes()
    @brush_sizes ||= group(*[1, 2, 3, 5, 10].map {|size|
      Reight::Button.new name: "Button Size #{size}", label: size do
        brush.size = size
        flash "Brush Size #{size}"
      end
    })
  end

  def colors()
    @colors ||= project.palette_colors.map {|color|
      rgb = self.color(color)
        .then {[red(_1), green(_1), blue(_1), alpha(_1)]}.map &:to_i
      Color.new(rgb) {canvas.color = rgb}
    }
  end

  def shapes()
    @shapes ||= group(
      Reight::Button.new(name: 'No Shape', label: 'None') {
        project.chips.at(*canvas.frame).shape = nil
      },
      Reight::Button.new(name: 'Rect Shape', label: 'Rect') {
        project.chips.at(*canvas.frame).shape = :rect
      },
      Reight::Button.new(name: 'Circle Shape', label: 'Circle') {
        project.chips.at(*canvas.frame).shape = :circle
      },
    )
  end

  def types()
    @types ||= group(
      Reight::Button.new(name: 'Object', label: 'Object') {
        project.chips.at(*canvas.frame).sensor = false
      },
      Reight::Button.new(name: 'Sensor', label: 'Sensor') {
        project.chips.at(*canvas.frame).sensor = true
      },
    )
  end

  def chip_changed(x, y, w, h)
    chip = project.chips.at x, y, w, h
    shapes[[nil, :rect, :circle].index(chip.shape)].click
    types[chip.sensor? ? 1 : 0].click
  end

  def update_active_tool()
    tools.each do |tool|
      tool.active = tool == canvas.tool
    end
  end

  def update_active_color()
    colors.each do |button|
      button.active = button.color == canvas.color
    end
  end

end# SpriteEditor
