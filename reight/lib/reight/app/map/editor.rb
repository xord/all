class Reight::MapEditor < Reight::ModelController

  extend Forwardable
  extend Reight::Hookable
  extend Reight::HasState

  C = Reight::CONTEXT__

  state :map do |new, old|
    @map = new
    group_history do
      self.layer = new&.at 0
      append_history [:set_map, new, old]
    end
  end

  state :layer do |new, old|
    @layer = new
    append_history [:set_layer, new, old]
  end

  state :sprite
  state :tool

  attr_reader :map, :layer, :sprite, :tool

  hook :map_name_changed

  def_delegators :@project, :maps, :sprites

  def_delegators :@settings,
    :asset_table_width,
    :asset_table_height,
    :asset_table_page_width,
    :asset_table_page_height

  def tools()
    @tools ||= [
      Reight::MapEditor::Brush     .new(self),
      Reight::MapEditor::Line      .new(self),
      Reight::MapEditor::StrokeRect.new(self),
      Reight::MapEditor::  FillRect.new(self)
    ]
  end

  def begin_editing(&block)
    history__.begin_grouping
    block.call if block
  ensure
    end_editing if block
  end

  def end_editing()
    history__.end_grouping
  end

  alias edit begin_editing

  def add_map(x, y, w, h)
    Reight::MapAsset.new(@project.get_next_id, w, h, x, y).tap {|map|
      map.push Reight::MapLayer.new
      group_history do
        maps.put map
        append_history [:add_map, map]
        self.map = map
      end
    }
  end

  def append_map()
    x, y, w, h = maps[-1].frame
    add_map x + w, y, w, h
  end

  def remove_map()
    return nil unless @map
    map, index = @map, maps.find_index(@map)
    group_history do
      maps.remove map
      append_history [:remove_map, map]
      self.map = maps[index] || maps[-1]
    end
    map
  end

  def set_map_name(name)
    old, @map.name = @map.name, name
    append_history [:set_map_name, @map.name, old]
    nil
  end

  def put_sprite(x, y, sprite = @sprite)
    return unless @layer && sprite
    x, y, w, h = self.class.bounds_for_put x, y, sprite.w, sprite.h
    return if @layer.each_tile(x, y, w, h).any?
    tile = @layer.put x, y, sprite
    append_history [:put_sprite, tile]
    nil
  end

  def remove_sprite(x, y)
    return unless @layer
    tile = @layer&.at(x, y) || return
    @layer.remove_tile tile
    append_history [:remove_sprite, tile]
    nil
  end
=begin
  def put_or_remove_chip(x, y, chip)
    return false unless x && y && chip
    m = canvas.map
    return false if !@deleting && m[x, y]&.id == chip.id

    result = false
    m.each_chip x, y, chip.w, chip.h do |ch|
      m.remove_chip ch
      result |= history.append [:remove_chip, ch.pos.x, ch.pos.y, ch.id]
    end
    unless @deleting
      m.put x, y, chip
      result |= history.append [:put_chip, x, y, chip.id]
    end
    result
  end
=end
  def undo()
    history__.undo do |action|
      case action
      in [:set_map,      _, old] then self.map      = old
      in [:set_map_name, _, old] then self.map.name = old
      in [:set_layer,    _, old] then self.layer    = old
      in [   :add_map, map]      then maps.remove map
      in [:remove_map, map]      then maps.put    map
      in [   :put_sprite, tile]  then remove_sprite tile.x, tile.y
      in [:remove_sprite, tile]  then    put_sprite tile.x, tile.y, tile.asset
      #in [  :select, sel, _]     then sel ? canvas.select(*sel) : canvas.deselect
      #in [:deselect, sel]        then       canvas.select(*sel)
      end
    end
  end

  def redo()
    history__.redo do |action|
      case action
      in [:set_map,      new, _] then self.map      = new
      in [:set_map_name, new, _] then self.map.name = new
      in [:set_layer,    new, _] then self.layer    = new
      in [   :add_map, map]      then maps.put    map
      in [:remove_map, map]      then maps.remove map
      in [   :put_sprite, tile]  then    put_sprite tile.x, tile.y, tile.asset
      in [:remove_sprite, tile]  then remove_sprite tile.x, tile.y
      #in [:remove_tile, x, y, id] then canvas.map.remove x, y
      #in [  :select, _, sel]      then canvas.select(*sel)
      #in [:deselect, _]           then canvas.deselect
      end
    end
  end

  def self.bounds_for_put(x, y, w, h)
    x, y = (x / w).to_i * w, (y / h).to_i * h
    [x, y, w, h]
  end

  private

=begin
  def canvas()
    @canvas ||= Canvas.new self, project.maps.first
  end

  def chips()
    @chips ||= Chips.new(self, project.chips).tap do |chips|
      chips.offset_changed do |offset|
        chips_index.index = chips.offset2index offset
      end
    end
  end

  def setup()
    super
    history.disable do
      tools[0].click
      chip_sizes[0].click
    end
  end

  def key_pressed()
    super
    shift, ctrl, cmd = %i[shift control command].map {pressing? _1}
    case key_code
    when LEFT  then canvas.x += SCREEN_WIDTH  / 2
    when RIGHT then canvas.x -= SCREEN_WIDTH  / 2
    when UP    then canvas.y += SCREEN_HEIGHT / 2
    when DOWN  then canvas.y -= SCREEN_HEIGHT / 2
    when :z    then shift ? self.redo : undo if ctrl || cmd
    when :b    then  brush.click
    when :l    then   line.click
    when :r    then (shift ? fill_rect : stroke_rect).click
    end
  end

  def window_resized()
    super
    [chip_sizes, tools].flatten.map(&:sprite)
      .each {|sp| sp.w = sp.h = BUTTON_SIZE}

    chips_index.sprite.tap do |sp|
      sp.w, sp.h = INDEX_SIZE, BUTTON_SIZE
      sp.x       = SPACE
      sp.y       = NAVIGATOR_HEIGHT + SPACE
    end
    chip_sizes.reverse.map {_1.sprite}.each.with_index do |sp, index|
      sp.x = SPACE + CHIPS_WIDTH - (sp.w + (sp.w + 1) * index)
      sp.y = chips_index.sprite.y
    end
    chips.sprite.tap do |sp|
      sp.x      = SPACE
      sp.y      = chip_sizes.last.sprite.bottom + SPACE
      sp.right  = chip_sizes.last.sprite.right
      sp.bottom = height - SPACE
    end
    map_index.sprite.tap do |sp|
      sp.w, sp.h = INDEX_SIZE, BUTTON_SIZE
      sp.x       = chip_sizes.last.sprite.right + SPACE
      sp.y       = chip_sizes.last.sprite.y
    end
    tools.map {_1.sprite}.each.with_index do |sp, index|
      sp.x = chips.sprite.right + SPACE + (sp.w + 1) * index
      sp.y = height - (SPACE + sp.h)
    end
    canvas.sprite.tap do |sp|
      sp.x      = map_index.sprite.x
      sp.y      = map_index.sprite.bottom + SPACE
      sp.right  = width - SPACE
      sp.bottom = tools.first.sprite.top - SPACE
    end
  end

  def undo(flash: true)
    history.undo do |action|
      case action
      end
      self.flash 'Undo!' if flash
    end
  end

  def redo(flash: true)
    history.redo do |action|
      case action
      end
      self.flash 'Redo!' if flash
    end
  end

  private

  def sprites()
    [chips_index, *chip_sizes, chips, map_index, *tools, canvas]
      .map(&:sprite) + super
  end

  def chips_index()
    @chips_index ||= Reight::Index.new max: project.chips_npages - 1 do |index|
      chips.offset = chips.index2offset index if index != chips.offset2index
    end
  end

  def chip_sizes()
    @chip_sizes ||= group(*[8, 16, 32].map {|size|
      Reight::Button.new name: "#{size}x#{size}", label: size do
        chips.set_frame chips.x, chips.y, size, size
      end
    })
  end

  def map_index()
    @map_index ||= Reight::Index.new do |index|
      canvas.map = project.maps[index] ||= Reight::Map.new
    end
  end

  def tools()
    @tools ||= group brush, line, stroke_rect, fill_rect
  end

  def brush        = @brush       ||= Brush.new(self)             {canvas.tool = _1}
  def line         = @line        ||= Line.new(self)              {canvas.tool = _1}
  def stroke_rect  = @stroke_rect ||= Rect.new(self, fill: false) {canvas.tool = _1}
  def   fill_rect  =   @fill_rect ||= Rect.new(self, fill: true)  {canvas.tool = _1}
=end
end# MapEditor
