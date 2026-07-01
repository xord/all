using Reight


class Reight::SpriteEditorInterface < Reight::AppInterface

  SPRITE_SIZES = [8, 16, 32]

  def initialize(editor, navigator)
    super

    e = editor
    e.sprite_changed      {sprite_changed _1, _2}
    e.sprite_size_changed {sprite_size_changed _1}
    e.anim_changed        {anim_changed _1, _2}
    e.anim_image_changed  {anim_image_changed _1, _2}
    e.tool_changed        {|tool|  tools.each  {_1.active = _1.tool  == tool}}
    e.color_changed       {|color| colors.each {_1.active = _1.color == color}}
    e.selection_changed   {canvas.selection = _1}

    sprite_table.selected           {e.sprite = _1}
    sprite_table.add_asset          {|x, y, w, h| e.add_sprite x, y, w, h}
    sprite_table.page_changed       {sprite_table_page.value = _1}
    sprite_table_page_prev.enabled? {sprite_table.page  > 0}
    sprite_table_page_prev.clicked  {sprite_table.page -= 1}
    sprite_table_page_next.enabled? {sprite_table.page  < sprite_table.npages - 1}
    sprite_table_page_next.clicked  {sprite_table.page += 1}
    sprite_remove.clicked           {e.remove_sprite}
    sprite_size.clicked             {select_sprite_size}
    sprite_name.changed             {e.set_sprite_name _1}

    anim_table.selected           {e.anim = _1}
    anim_table.add_asset          {|x, y, w, h| e.add_anim x, y, w, h}
    anim_table.page_changed       {anim_table_page.value = _1}
    anim_table_page_prev.enabled? {anim_table.page > 0}
    anim_table_page_prev.clicked  {anim_table.page -= 1}
    anim_table_page_next.enabled? {anim_table.page < anim_table.npages - 1}
    anim_table_page_next.clicked  {anim_table.page += 1}

    anim_name.changed               {e.set_anim_name _1}
    anim_image_remove.clicked       {e.remove_anim_image}
    anim_images.selected            {e.anim_image = _1}
    anim_images.add_image           {e.add_anim_image _1}

    canvas.canvas_pressed  {|*a| e.tool&.canvas_pressed(*a)}
    canvas.canvas_released {|*a| e.tool&.canvas_released(*a)}
    canvas.canvas_moved    {|*a| e.tool&.canvas_moved(*a)}
    canvas.canvas_dragged  {|*a| e.tool&.canvas_dragged(*a)}
    canvas.canvas_clicked  {|*a| e.tool&.canvas_clicked(*a)}

    tools.each  {|button| button.clicked {e.tool  = button.tool}}
    colors.each {|button| button.clicked {e.color = button.color}}

    e.disable_history do
      sprite_table.assets = e.sprites
      e.sprite_size       = 16
      e.tool              = e.tools.find {_1.class == Reight::SpriteEditor::Brush}
      e.color             = e.colors[12]

      e.add_sprite 0, 0, e.sprite_size, e.sprite_size if e.sprites.empty?
    end
  end

  def sprite_changed(sprite, old)
    sprite_table.select sprite
    anim_table.assets             = sprite
    anim_table.size_for_new_asset = sprite ? sprite.w : nil
    bind(__method__, sprite, old) {sprite_name.value = sprite.name}
  end

  def select_sprite_size()
    sp = sprite_size.sprite
    overlay alpha: 50 do |o|
      SPRITE_SIZES.each.with_index do |size, index|
        index -= SPRITE_SIZES.index(editor.sprite_size)
        b      = o.button(sp.x, sp.y, sp.w, sp.h, label: size, shadow: 1) {o.close size}
        from   = sp.x
        to     = sp.x + (sp.w + space_m) * index
        animate_value(0.2, from: from, to: to) {b.sprite.x = _1}
      end
      o.on_close {editor.sprite_size = _1 if _1}
    end
  end

  def sprite_size_changed(size)
    sprite_size.label = size
    sprite_table.size_for_new_asset = size
  end

  def anim_changed(anim, old)
    anim_table.select anim
    anim_images.anim = anim
    bind(__method__, anim, old) {anim_name.value = anim&.name}
  end

  def anim_image_changed(image, old)
    anim_images.select image
    canvas.image = image
  end

  def sprites()
    super + [
      sprite_table_page_prev,
      sprite_table_page,
      sprite_table_page_next,
      sprite_remove,
      sprite_size,
      sprite_table,
      anim_table_page_prev,
      anim_table_page,
      anim_table_page_next,
      anim_table,
      sprite_name,
      anim_name,
      anim_image_remove,
      anim_images,
      canvas,
      *tools,
      *colors
    ].map(&:sprite)
  end

  def sprite_table()           = @sprite_table           ||= Reight::AssetTable.new(
    editor.asset_table_width,      editor.asset_table_width,
    editor.asset_table_page_width, editor.asset_table_page_height)

  def sprite_table_page()      = @sprite_table_page      ||= Reight::Label.new(0, align: CENTER)

  def sprite_table_page_prev() = @sprite_table_page_prev ||= Reight::Button.new(label: '<')

  def sprite_table_page_next() = @sprite_table_page_next ||= Reight::Button.new(label: '>')

  def sprite_remove()          = @sprite_remove          ||= Reight::Button.new(label: '-')

  def sprite_size()            = @sprite_size            ||= Reight::Button.new(label: editor.sprite_size)

  def sprite_name()            = @sprite_name            ||= Reight::Label.new(
    editable: true, regexp: /^\w+$/)

  def anim_table()             = @anim_table             ||= Reight::AssetTable.new(
    editor.asset_table_width,      editor.asset_table_width,
    editor.asset_table_page_width, editor.asset_table_page_width)

  def anim_table_page()        = @anim_table_page        ||= Reight::Label.new(0, align: CENTER)

  def anim_table_page_prev()   = @anim_table_page_prev   ||= Reight::Button.new(label: '<')

  def anim_table_page_next()   = @anim_table_page_next   ||= Reight::Button.new(label: '>')

  def anim_name()              = @anim_name              ||= Reight::Label.new(
    editable: true, regexp: /^\w+$/)

  def anim_image_remove()      = @anim_image_remove      ||= Reight::Button.new(label: '-')

  def anim_images()            = @anim_images            ||= Reight::SpriteEditor::AnimImageList.new

  def canvas()                 = @canvas                 ||= Reight::SpriteEditor::Canvas.new

  def tools()                  = @tools                  ||= editor.tools.map {|tool|
    Reight::Button.new(name: tool.name, icon: r8.icon(tool.icon_index, 2, 8)).tap do |b|
      b.set_help left: tool.help_text
      b.singleton_class.define_method(:tool) {tool}
    end
  }

  def colors()                 = @colors                 ||=
    editor.colors.map {Reight::SpriteEditor::Color.new _1}

  def update_layout()
    super

    app  = Reight::App
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
    sprite_size.sprite.tap do |sp|
      sp.w = sp.h = app::BUTTON_SIZE
      sp.x        = prev.right - sp.w
      sp.y        = sprite_table_page_next.sprite.y
    end
    prev = sprite_remove.sprite.tap do |sp|
      sp.w = sp.h = app::BUTTON_SIZE
      sp.x        = sprite_size.sprite.x - space_l - sp.w
      sp.y        = sprite_size.sprite.y
    end
    prev = anim_table_page_prev.sprite.tap do |sp|
      sp.x        = space_l
      sp.y        = sprite_table.sprite.bottom + space_l
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = anim_table_page.sprite.tap do |sp|
      sp.x        = prev.right + space_s
      sp.y        = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = anim_table_page_next.sprite.tap do |sp|
      sp.x        = prev.right + space_s
      sp.y        = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = anim_table.sprite.tap do |sp|
      sp.x      = sprite_table.sprite.x
      sp.y      = prev.bottom + space_m
      sp.w      = sprite_table.sprite.w
      sp.bottom = height - space_l
    end
    prev = anim_image_remove.sprite.tap do |sp|
      sp.w = sp.h = app::BUTTON_SIZE
      sp.x        = width - space_l - sp.w
      sp.y        = sprite_table_page_prev.sprite.y
    end
    prev = sprite_name.sprite.tap do |sp|
      sp.x = sprite_table.sprite.right + space_l
      sp.y = prev.y
      sp.w = 100
      sp.h = app::BUTTON_SIZE
    end
    prev = anim_name.sprite.tap do |sp|
      sp.x     = prev.right + space_m
      sp.y     = prev.y
      sp.right = anim_image_remove.sprite.x - space_m
      sp.h     = app::BUTTON_SIZE
    end
    prev = anim_images.sprite.tap do |sp|
      sp.x     = sprite_name.sprite.x
      sp.y     = sprite_name.sprite.bottom + space_m
      sp.right = width - space_l
      sp.h     = 32 + Reight::SpriteEditor::AnimImageList::PADDING * 2
    end
    prev = canvas.sprite.tap do |sp|
      x, y = prev.x, prev.bottom + space_l
      w, h = width - x - space_l, height - y - space_l
      sp.w = sp.h = h
      sp.x = x + ((w - sp.w) / 2).to_i
      sp.y = y
    end
    tools.map(&:sprite).each.with_index do |sp, index|
      sp.w = sp.h = app::BUTTON_SIZE
      csp, all_h  = canvas.sprite, (sp.h + space_s) * tools.size
      sp.x        = csp.x - space_l - sp.w
      sp.y        = csp.y + ((csp.h - all_h) / 2).to_i + (sp.h + space_s) * index
    end
    colors.map(&:sprite).each.with_index do |sp, index|
      sp.w = (app::BUTTON_SIZE * 0.8).floor
      sp.h = app::BUTTON_SIZE
      sp.x = canvas.sprite.right + space_l                             + sp.w * (index / 8)
      sp.y = canvas.sprite.y + ((canvas.sprite.h - sp.h * 8) / 2).to_i + sp.h * (index % 8)
    end
  end

  def key_pressed(pressings)
    super

    shift, ctrl, cmd = [SHIFT, CONTROL, COMMAND].map {pressings.include? _1}
    e, se            = editor, Reight::SpriteEditor
    case key_code
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

  private

  def space_l() = Reight::App::SPACE

  def space_m() = space_l / 2

  def space_s() = 1

end# SpriteEditorInterface
