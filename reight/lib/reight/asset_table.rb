class Reight::AssetTable

  C       = Reight::CONTEXT__
  PADDING = 1

  include Reight::Hookable

  def initialize(width, height, page_width, page_height)
    hook :selected
    hook :page_changed

    w = width  / page_width .to_f
    h = height / page_height.to_f
    raise unless w == w.to_i && h == h.to_i

    @width, @height, @page_width, @page_height =
      [width, height, page_width, page_height].map(&:to_i)

    @assets, @offset = nil, Rays::Point.new(0)
    @npages          = (w * h).to_i

    self.page = 0
  end

  attr_reader :assets, :page, :npages

  def assets=(assets)
    return if assets == @assets
    @assets = assets
    select @assets&.at 0
  end

  def select(asset)
    return if asset == @asset
    id     = asset&.id
    return unless @assets&.find {_1.id == id} if id
    @asset = asset
    selected! @asset
  end

  def page=(page)
    return if page == @page
    return if page < 0 || @npages <= page
    @page                 = page
    @offset.x, @offset.y, = page_bounds__(@page).to_a(2)
    page_changed! @page
  end

  def get_frame_for_new_asset(w, h)
    asset_frames = assets_on_page__(@page).map {Rays::Bounds.new(*_1.frame)}
    pb           = page_bounds__ page
    xs           = (pb.left..(pb.right - w + 1)).step(8).to_a
    ys           = (pb.top..(pb.bottom - h + 1)).step(8).to_a
    xs.product(ys).map {|y, x| [x, y, w, h]}.find do |frame|
      b = Rays::Bounds.new(*frame)
      asset_frames.all? {|asset_frame| (asset_frame & b).then {_1.w == 0 || _1.h == 0}}
    end
  end

  def draw()
    sp = sprite
    C.clip sp.x, sp.y, sp.w, sp.h
    C.fill 190
    C.no_stroke
    C.rect 0, 0, sp.w, sp.h
    C.translate PADDING + -@offset.x, PADDING + -@offset.y

    @assets&.each do |asset|
      C.fill 0
      C.no_stroke
      C.rect asset.x, asset.y, asset.w, asset.h
      C.image asset.image, asset.x, asset.y
    end

    if @asset
      C.no_fill
      C.stroke 255
      C.rect @asset.x, @asset.y, @asset.w + 1, @asset.h + 1
    end
  end

  def mouse_clicked(x, y)
    a = @assets.find {|a| a.hit? x, y}
    select a if a
  end

  def sprite()
    @sprite ||= RubySketch::Sprite.new.tap do |sp|
      sp.draw           {draw}
      #sp.mouse_pressed  {mouse_pressed  sp.mouse_x, sp.mouse_y}
      #sp.mouse_released {mouse_released sp.mouse_x, sp.mouse_y}
      #sp.mouse_dragged  {mouse_dragged  sp.mouse_x, sp.mouse_y}
      sp.mouse_clicked  {mouse_clicked  sp.mouse_x, sp.mouse_y}
    end
  end

  private

  # @private
  def assets_on_page__(page)
    pb = page_bounds__ page
    @assets.select do |asset|
      b = pb & Rays::Bounds.new(*asset.frame)
      b.w > 0 && b.h > 0
    end
  end

  # @private
  def page_bounds__(page)
    ncols = @width / @page_width
    Rays::Bounds.new(
      (page % ncols) * @page_width,
      (page / ncols) * @page_height,
      @page_width,
      @page_height)
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
end# AssetTable
