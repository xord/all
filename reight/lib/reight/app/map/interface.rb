using Reight


class Reight::MapEditorInterface < Reight::AppInterface

  def initialize(editor, navigator)
    super

    e = editor
    e.map_changed    {map_changed _1, _2}
    e.sprite_changed {sprite_changed _1}
    e.tool_changed   {|tool| tools.each {_1.active = _1.tool == tool}}

    sprite_table.selected           {e.sprite = _1}
    sprite_table.page_changed       {sprite_table_page.value = _1}
    sprite_table_page_prev.enabled? {sprite_table.page  > 0}
    sprite_table_page_prev.clicked  {sprite_table.page -= 1}
    sprite_table_page_next.enabled? {sprite_table.page  < sprite_table.npages - 1}
    sprite_table_page_next.clicked  {sprite_table.page += 1}
    mini_map.offset_changed         {canvas.offset = _1}
    map_prev  .enabled?             {get_map_index > 0}
    map_prev  .clicked              {e.map = e.maps[get_map_index - 1]}
    map_next  .enabled?             {get_map_index < e.maps.size - 1}
    map_next  .clicked              {e.map = e.maps[get_map_index + 1]}
    map_add   .clicked              {e.append_map}
    map_remove.enabled?             {e.maps.size > 1}
    map_remove.clicked              {e.remove_map}
    map_name  .changed              {e.set_map_name _1}
    canvas.offset_changed           {mini_map.offset = _1}
    canvas.size_changed             {mini_map.size   = _1}

    canvas.canvas_pressed  {|*a| e.tool&.canvas_pressed(*a)}
    canvas.canvas_released {|*a| e.tool&.canvas_released(*a)}
    canvas.canvas_moved    {|*a| e.tool&.canvas_moved(*a)}
    canvas.canvas_dragged  {|*a| e.tool&.canvas_dragged(*a)}
    canvas.canvas_clicked  {|*a| e.tool&.canvas_clicked(*a)}

    tools.each {|button| button.clicked {e.tool = button.tool}}

    e.disable_history do
      sprite_table.assets = e.sprites
      e.map               = e.maps[0]
      e.tool              = e.tools.find {_1.class == Reight::MapEditor::Brush}

      e.add_map 0, 0, 32, 32 if e.maps.empty?
    end
  end

  def map_changed(map, old)
    canvas.map      = map
    mini_map.map    = map
    map_index.value = get_map_index
    bind(__method__, map, old) {map_name.value = map&.name}
  end

  def sprite_changed(sprite)
    sprite_table.select sprite
    canvas.sprite = sprite
  end

  def get_map_index()
    editor.maps&.find_index(editor.map) || 0
  end

  def sprites()
    super + [
      sprite_table_page_prev,
      sprite_table_page,
      sprite_table_page_next,
      sprite_table,
      mini_map,
      map_prev,
      map_index,
      map_next,
      map_add,
      map_remove,
      map_name,
      canvas,
      *tools
    ].map(&:sprite)
  end

  def sprite_table()           = @sprite_table           ||= Reight::AssetTable.new(
    editor.asset_table_width,      editor.asset_table_width,
    editor.asset_table_page_width, editor.asset_table_page_height)

  def sprite_table_page()      = @sprite_table_page      ||= Reight::Label.new(0, align: CENTER)

  def sprite_table_page_prev() = @sprite_table_page_prev ||= Reight::Button.new(label: '<')

  def sprite_table_page_next() = @sprite_table_page_next ||= Reight::Button.new(label: '>')

  def mini_map()               = @mini_map               ||= Reight::MapEditor::MiniMap.new

  def map_index()              = @map_index              ||= Reight::Label.new(0, align: CENTER)

  def map_prev()               = @map_prev               ||= Reight::Button.new(label: '<')

  def map_next()               = @map_next               ||= Reight::Button.new(label: '>')

  def map_add()                = @map_add                ||= Reight::Button.new(label: '+')

  def map_remove()             = @map_remove             ||= Reight::Button.new(label: '-')

  def map_name()               = @map_name               ||= Reight::Label.new(
    editable: true, regexp: /^\w+$/)

  def canvas()                 = @canvas                 ||= Reight::MapEditor::Canvas.new

  def tools()                  = @tools                  ||= editor.tools.map {|tool|
    Reight::Button.new(name: tool.name, icon: r8.icon(tool.icon_index, 2, 8)).tap do |b|
      b.set_help left: tool.help_text
      b.singleton_class.define_method(:tool) {tool}
    end
  }

  def update_layout()
    super

    app                       = Reight::App
    space_l, space_m, space_s = app::SPACE, app::SPACE / 2, 1

    prev = sprite_table_page_prev.sprite.tap do |sp|
      sp.x        = space_l
      sp.y        = app::NAVIGATOR_HEIGHT + space_l
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = sprite_table_page.sprite.tap do |sp|
      sp.x        = prev.right + space_s
      sp.y        = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = sprite_table_page_next.sprite.tap do |sp|
      sp.x        = prev.right + space_s
      sp.y        = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = sprite_table.sprite.tap do |sp|
      sp.x = sprite_table_page_prev.sprite.x
      sp.y = sprite_table_page_prev.sprite.bottom + space_m
      sp.w = editor.asset_table_page_width  + Reight::AssetTable::PADDING * 2
      sp.h = editor.asset_table_page_height + Reight::AssetTable::PADDING * 2
    end
    prev = mini_map.sprite.tap do |sp|
      sp.x      = prev.x
      sp.y      = prev.bottom + space_l
      sp.w      = prev.w
      sp.bottom = height - space_l
    end
    prev = map_prev.sprite.tap do |sp|
      sp.x        = prev.right + space_l
      sp.y        = sprite_table_page_prev.sprite.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = map_index.sprite.tap do |sp|
      sp.x        = prev.right + space_s
      sp.y        = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = map_next.sprite.tap do |sp|
      sp.x        = prev.right + space_s
      sp.y        = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = map_add.sprite.tap do |sp|
      sp.x        = prev.right + space_s
      sp.y        = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = map_remove.sprite.tap do |sp|
      sp.x        = prev.right + space_s
      sp.y        = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = map_name.sprite.tap do |sp|
      sp.x     = prev.right + space_m
      sp.y     = prev.y
      sp.h     = prev.h
      sp.right = width - space_l
    end
    tools.map(&:sprite).each.with_index do |sp, index|
      sp.w = sp.h = app::BUTTON_SIZE
      sp.x        = map_prev.sprite.x + (sp.w + space_s) * index
      sp.y        = height - space_l - sp.h
    end
    prev = canvas.sprite.tap do |sp|
      sp.x      = map_prev.sprite.x
      sp.y      = map_prev.sprite.bottom + space_m
      sp.right  = width                - space_l
      sp.bottom = tools.first.sprite.y - space_m
    end
  end

=begin
  def initialize(project, editor)
    @project = pj = project
    @editor  = e  = editor

    e.sprite_changed      {sprite_changed _1}
    e.sprite_size_changed {sprite_size_changed _1}
    e.anim_changed        {anim_images.anim = _1}
    e.anim_changed        {anim_name.value = _1.name}
    e.anim_image_changed  {anim_images.select _1}
    e.anim_image_changed  {canvas.image = _1}
    e.tool_changed        {|tool|  tools.each  {_1.active = _1.tool  == tool}}
    e.color_changed       {|color| colors.each {_1.active = _1.color == color}}
    e.selection_changed   {canvas.selection = _1}

    sprite_table.selected           {e.sprite = _1}
    sprite_table.add_asset          {|x, y, w, h| e.add_sprite x, y, w, h}
    sprite_table.page_changed       {sprite_table_page.value = _1 + 1}
    sprite_table_page_prev.enabled? {sprite_table.page > 0}
    sprite_table_page_prev.clicked  {sprite_table.page -= 1}
    sprite_table_page_next.enabled? {sprite_table.page < sprite_table.npages - 1}
    sprite_table_page_next.clicked  {sprite_table.page += 1}
    sprite_table_add.clicked        {sprite_table_add_clicked}
    sprite_sizes.each {|button|
      button.clicked                {e.sprite_size = _1.label}
    }
    sprite_name.changed             {e.sprite.name = _1}
    anim_prev.clicked               {e.anim_image = e.anim&.at get_anim_image_index - 1}
    anim_next.clicked               {e.anim_image = e.anim&.at get_anim_image_index + 1}
    #anim_add.clicked                {e.add_anim_image}
    anim_name
    anim_images.selected            {e.anim_image = _1}
    anim_images.add_image           {e.add_anim_image _1}
    canvas.canvas_pressed           {|x, y, b| e.canvas_pressed  x, y, b}
    canvas.canvas_released          {|x, y, b| e.canvas_released x, y, b}
    canvas.canvas_moved             {|x, y|    e.canvas_moved    x, y}
    canvas.canvas_dragged           {|x, y, b| e.canvas_dragged  x, y, b}
    canvas.canvas_clicked           {|x, y, b| e.canvas_clicked  x, y, b}

    tools.each  {|button| button.clicked {e.tool  = button.tool}}
    colors.each {|button| button.clicked {e.color = button.color}}

    e.disable_history do
      sprite_table.assets = project.sprites
      e.sprite_size       = 16
      e.tool              = e.tools.find {_1.class == Reight::SpriteEditor::Brush}
      e.color             = e.colors[12]

      e.add_sprite 0, 0, e.sprite_size, e.sprite_size if @project.sprites.empty?
    end
  end

  def sprite_changed(sprite)
    sprite_table.select sprite
    sprite_name.value = sprite.name
  end

  def sprite_size_changed(size)
    sprite_sizes.each {_1.active = _1.label == size}
    sprite_table.size_for_new_asset = size
  end

  def sprite_table_add_clicked()
    x, y, w, h = sprite_table.get_frame_for_new_asset || return
    @editor.add_sprite x, y, w, h
  end

  def get_anim_image_index()
    @editor.anim.find_index @editor.anim_image
  end

  def sprites()
    [
      sprite_name,
      anim_name,
      anim_prev,
      anim_next,
      #anim_add,
      anim_images,
      *tools,
      *colors
    ].map(&:sprite)
  end

  def sprite_table_add()       = @sprite_table_add       ||= Reight::Button.new(label: '+')

  def sprite_sizes()           = @sprite_sizes           ||= [8, 16, 32].map {Reight::Button.new(label: _1)}

  def sprite_name()            = @sprite_name            ||= Reight::Text.new(
    label: 'Name: ', editable: true, regexp: /^\w*$/)

  def anim_name()              = @anim_name              ||= Reight::Text.new

  def anim_prev()              = @anim_prev              ||= Reight::Button.new(label: '<')

  def anim_next()              = @anim_next              ||= Reight::Button.new(label: '>')

  def anim_add()               = @anim_add               ||= Reight::Button.new(label: '+')

  def anim_images()            = @anim_images            ||= Reight::SpriteEditor::AnimImageList.new

  def tools()                  = @tools                  ||= @editor.tools.map {|tool|
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
    @editor.colors.map {Reight::SpriteEditor::Color.new _1}

  def update_layout()

    prev = sprite_table_add.sprite.tap do |sp|
      sp.x = prev.right + space_m
      sp.y = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
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

  def key_pressed(pressings)
    shift, ctrl, cmd = [SHIFT, CONTROL, COMMAND].map {pressings.include? _1}
    e, se            = @editor, Reight::SpriteEditor
    case C.key_code
    when :z then shift ? e.redo : e.undo if ctrl || cmd
    when :c then e.copy  if ctrl || cmd
    when :x then e.cut   if ctrl || cmd
    when :v then e.paste if ctrl || cmd
    when :s then e.tool = e.tools.find {_1.class == se::Select}
    when :b then e.tool = e.tools.find {_1.class == se::Brush}
    when :l then e.tool = e.tools.find {_1.class == se::Line}
    when :f then e.tool = e.tools.find {_1.class == se::Fill}
    when :r then e.tool = e.tools.find {_1.class == (shift ? se::FillRect    : se::StrokeRect)}
    when :e then e.tool = e.tools.find {_1.class == (shift ? se::FillEllipse : se::StrokeEllipse)}
    end
  end
=end
end# MapEditorInterface
