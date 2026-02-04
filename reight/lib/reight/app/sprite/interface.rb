class Reight::SpriteEditor::Interface

  C = Reight::CONTEXT__

  def initialize(project, controller)
    @project    = pj = project
    @controller = c  = controller

    c.sprite_changed      {sprite_changed _1}
    c.sprite_size_changed {|size| sprite_sizes.each {_1.active = _1.label == size}}
    c.anim_changed        {anim_images.anim = _1}
    c.anim_changed        {anim_name.value = _1.name}
    c.anim_image_changed  {anim_images.select _1}
    c.anim_image_changed  {canvas.image = _1}
    c.tool_changed        {|tool|  tools.each  {_1.active = _1.tool  == tool}}
    c.color_changed       {|color| colors.each {_1.active = _1.color == color}}
    c.selection_changed   {canvas.selection = _1}

    sprite_table.selected          {c.sprite = _1}
    sprite_table.page_changed      {sprite_table_page.value = _1 + 1}
    sprite_table_page_prev.clicked {sprite_table.page -= 1}
    sprite_table_page_next.clicked {sprite_table.page += 1}
    sprite_table_add.clicked       {sprite_table_add_clicked}
    sprite_sizes.each {|button|
      button.clicked               {c.sprite_size = _1.label}
    }
    sprite_name.changed            {c.sprite.name = _1}
    anim_prev.clicked              {c.anim_image = c.anim&.at get_anim_image_index - 1}
    anim_next.clicked              {c.anim_image = c.anim&.at get_anim_image_index + 1}
    anim_add.clicked               {anim_add_clicked}
    anim_name
    anim_images.selected           {c.anim_image = _1}
    canvas.canvas_pressed          {|x, y, b| c.canvas_pressed  x, y, b}
    canvas.canvas_released         {|x, y, b| c.canvas_released x, y, b}
    canvas.canvas_moved            {|x, y|    c.canvas_moved    x, y}
    canvas.canvas_dragged          {|x, y, b| c.canvas_dragged  x, y, b}
    canvas.canvas_clicked          {|x, y, b| c.canvas_clicked  x, y, b}

    tools.each  {|button| button.clicked {c.tool  = button.tool}}
    colors.each {|button| button.clicked {c.color = button.color}}

    sprite_table.assets = project.sprites
    c.sprite_size       = 16
    c.tool              = c.tools.find {_1.class == Reight::SpriteEditor::Brush}
    c.color             = c.colors.first
  end

  def sprite_changed(sprite)
    sprite_table.select sprite
    sprite_name.value = sprite.name
  end

  def sprite_table_add_clicked()
    size  = @controller.sprite_size
    frame = sprite_table.get_frame_for_new_asset(size, size) || return
    sp    = @project.create_sprite_asset(*frame)
    @project.sprites.push sp
    @controller.sprite = sp
  end

  def anim_add_clicked()
    image = @controller.anim_image.dup
    @controller.anim.insert get_anim_image_index + 1, image
    @controller.anim_image = image
  end

  def get_anim_image_index()
    @controller.anim.find_index @controller.anim_image
  end

  def sprites()
    [
      sprite_table_page_prev,
      sprite_table_page,
      sprite_table_page_next,
      sprite_table_add,
      *sprite_sizes,
      sprite_table,
      sprite_name,
      anim_name,
      anim_prev,
      anim_next,
      anim_add,
      anim_images,
      canvas,
      *tools,
      *colors
    ].map(&:sprite)
  end

  def sprite_table()           = @sprite_table           ||= Reight::AssetTable.new(
    @project.settings.sprites_width,
    @project.settings.sprites_width,
    @project.settings.sprites_page_width,
    @project.settings.sprites_page_height)

  def sprite_table_page()      = @sprite_table_page      ||= Reight::Text.new(1, align: CENTER)

  def sprite_table_page_prev() = @sprite_table_page_prev ||= Reight::Button.new(label: '<')

  def sprite_table_page_next() = @sprite_table_page_next ||= Reight::Button.new(label: '>')

  def sprite_table_add()       = @sprite_table_add       ||= Reight::Button.new(label: '+')

  def sprite_sizes()           = @sprite_sizes           ||= [8, 16, 32].map {Reight::Button.new(label: _1)}

  def sprite_name()            = @sprite_name            ||= Reight::Text.new(
    label: 'Name: ', editable: true, regexp: /^[\w_]*$/)

  def anim_name()              = @anim_name              ||= Reight::Text.new

  def anim_prev()              = @anim_prev              ||= Reight::Button.new(label: '<')

  def anim_next()              = @anim_next              ||= Reight::Button.new(label: '>')

  def anim_add()               = @anim_add               ||= Reight::Button.new(label: '+')

  def anim_images()            = @anim_images            ||= Reight::SpriteEditor::AnimImageList.new

  def canvas()                 = @canvas                 ||= Reight::SpriteEditor::Canvas.new

  def tools()                  = @tools                  ||= @controller.tools.map {|tool|
    name, icon_index, help_text =
      case tool
      when Reight::SpriteEditor::Select        then ['Select',         0, 'Select or Move']
      when Reight::SpriteEditor::Brush         then ['Brush',          1, 'Brush']
      when Reight::SpriteEditor::Fill          then ['Fill',           2, 'Fill']
      when Reight::SpriteEditor::Line          then ['Line',           4, 'Line']
      when Reight::SpriteEditor::StrokeRect    then ['Stroke Rect',    5, 'Stroke Rect']
      when Reight::SpriteEditor::  FillRect    then [  'Fill Rect',    6,   'Fill Rect']
      when Reight::SpriteEditor::StrokeEllipse then ['Stroke Ellipse', 7, 'Stroke Ellipse']
      when Reight::SpriteEditor::  FillEllipse then [  'Fill Ellipse', 8,   'Fill Ellipse']
      end
    Reight::Button.new(name: name, icon: r8.icon(icon_index, 2, 8)).tap do |b|
      b.set_help left: help_text
      b.singleton_class.define_method(:tool) {tool}
    end
  }

  def colors()                 = @colors                 ||=
    @controller.colors.map {Reight::SpriteEditor::Color.new _1}

  def update_layout()
    app                       = Reight::App
    space_l, space_m, space_s = app::SPACE, app::SPACE / 2, 1

    prev = sprite_table_page_prev.sprite.tap do |sp|
      sp.x = space_l
      sp.y = app::NAVIGATOR_HEIGHT + space_l
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = sprite_table_page.sprite.tap do |sp|
      sp.x = prev.right + space_s
      sp.y = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = sprite_table_page_next.sprite.tap do |sp|
      sp.x = prev.right + space_s
      sp.y = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = sprite_table_add.sprite.tap do |sp|
      sp.x = prev.right + space_m
      sp.y = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = sprite_table.sprite.tap do |sp|
      sp.x = sprite_table_page_prev.sprite.x
      sp.y = sprite_table_page_prev.sprite.bottom + space_m
      sp.w = @project.settings.sprites_page_width  + Reight::AssetTable::PADDING * 2
      sp.h = @project.settings.sprites_page_height + Reight::AssetTable::PADDING * 2
    end
    sprite_sizes.map(&:sprite).reverse.map.with_index do |sp, index|
      sp.w = sp.h = app::BUTTON_SIZE
      sp.x = prev.right - sp.w - (sp.w + space_m) * index
      sp.y = sprite_table_add.sprite.y
    end
    prev = sprite_name.sprite.tap do |sp|
      sp.x = prev.x
      sp.y = prev.bottom + space_l
      sp.w = prev.w
      sp.h = app::BUTTON_SIZE
    end
    prev = anim_prev.sprite.tap do |sp|
      sp.x = sprite_table.sprite.right + space_l
      sp.y = sprite_table_page_prev.sprite.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = anim_next.sprite.tap do |sp|
      sp.x = prev.right + space_m
      sp.y = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = anim_add.sprite.tap do |sp|
      sp.x = prev.right + space_m
      sp.y = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = anim_name.sprite.tap do |sp|
      sp.x     = prev.right + space_m
      sp.y     = prev.y
      sp.right = C.width - space_l
      sp.h     = app::BUTTON_SIZE
    end
    prev = anim_images.sprite.tap do |sp|
      sp.x     = anim_prev.sprite.x
      sp.y     = anim_prev.sprite.bottom + space_m
      sp.right = C.width - space_l
      sp.h     = 32 + Reight::SpriteEditor::AnimImageList::PADDING * 2
    end
    prev = canvas.sprite.tap do |sp|
      x, y = prev.x, prev.bottom + space_l
      w, h = C.width - x - space_l, C.height - y - space_l
      sp.w = sp.h = h
      sp.x = x + ((w - sp.w) / 2).to_i
      sp.y = y
    end
    tools.map(&:sprite).each.with_index do |sp, index|
      sp.w  = sp.h = app::BUTTON_SIZE
      sp.x  = canvas.sprite.x - space_l - sp.w
      all_h = (sp.h + 1) * tools.size
      sp.y  = canvas.sprite.y + ((canvas.sprite.h - all_h) / 2).to_i + (sp.h + 1) * index
    end
    colors.map(&:sprite).each.with_index do |sp, index|
      sp.w  = (app::BUTTON_SIZE * 0.8).floor
      sp.h  = app::BUTTON_SIZE
      sp.x  = canvas.sprite.right + space_l                             + sp.w * (index / 8)
      sp.y  = canvas.sprite.y + ((canvas.sprite.h - sp.h * 8) / 2).to_i + sp.h * (index % 8)
    end
  end

end# SpriteEditor::Interface
