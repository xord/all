using Reight


class Reight::SpriteEditorInterface < Reight::ViewController

  def initialize(editor)
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
    sprite_name.changed             {e.set_sprite_name _1}
    anim_prev.enabled?              {get_anim_index > 0}
    anim_prev.clicked               {e.anim = e.sprite&.at get_anim_index - 1}
    anim_next.enabled?              {get_anim_index < (e.sprite&.size || 0) - 1}
    anim_next.clicked               {e.anim = e.sprite&.at get_anim_index + 1}
    anim_add   .clicked             {e.add_anim}
    anim_remove.enabled?            {(e.sprite&.size || 0) > 0}
    anim_remove.clicked             {e.remove_anim}
    anim_name.changed               {e.set_anim_name _1}
    anim_image_remove.clicked       {e.remove_anim_image}
    anim_images.selected            {e.anim_image = _1}
    anim_images.add_image           {e.add_anim_image _1}

    canvas.canvas_pressed  {|*a| e.tool&.canvas_pressed(*a)}
    canvas.canvas_released {|*a| e.tool&.canvas_released(*a)}
    canvas.canvas_moved    {|*a| e.tool&.canvas_moved(*a)}
    canvas.canvas_dragged  {|*a| e.tool&.canvas_dragged(*a)}
    canvas.canvas_clicked  {|*a| e.tool&.canvas_clicked(*a)}

    sprite_sizes.each {|button| button.clicked {e.sprite_size = _1.label}}
    tools.each        {|button| button.clicked {e.tool        = button.tool}}
    colors.each       {|button| button.clicked {e.color       = button.color}}

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
    bind(__method__, sprite, old) {sprite_name.value = sprite.name}
  end

  def sprite_size_changed(size)
    sprite_sizes.each {_1.active = _1.label == size}
    sprite_table.size_for_new_asset = size
  end

  def anim_changed(anim, old)
    anim_index.value = get_anim_index
    anim_images.anim = anim
    bind(__method__, anim, old) {anim_name.value = anim&.name}
  end

  def anim_image_changed(image, old)
    anim_images.select image
    canvas.image = image
  end

  def get_anim_index()
    @editor.sprite&.find_index(@editor&.anim) || 0
  end

  def sprites()
    [
      sprite_table_page_prev,
      sprite_table_page,
      sprite_table_page_next,
      sprite_remove,
      *sprite_sizes,
      sprite_table,
      sprite_name,
      anim_name,
      anim_prev,
      anim_index,
      anim_next,
      anim_add,
      anim_remove,
      anim_image_remove,
      anim_images,
      canvas,
      *tools,
      *colors
    ].map(&:sprite)
  end

  def sprite_table()           = @sprite_table           ||= Reight::AssetTable.new(
    @editor.asset_table_width,      @editor.asset_table_width,
    @editor.asset_table_page_width, @editor.asset_table_page_height)

  def sprite_table_page()      = @sprite_table_page      ||= Reight::Label.new(0, align: CENTER)

  def sprite_table_page_prev() = @sprite_table_page_prev ||= Reight::Button.new(label: '<')

  def sprite_table_page_next() = @sprite_table_page_next ||= Reight::Button.new(label: '>')

  def sprite_remove()          = @sprite_remove          ||= Reight::Button.new(label: '-')

  def sprite_sizes()           = @sprite_sizes           ||= [8, 16, 32].map {Reight::Button.new(label: _1)}

  def sprite_name()            = @sprite_name            ||= Reight::Label.new(
    editable: true, prefix: 'Name: ', regexp: /^\w+$/)

  def anim_name()              = @anim_name              ||= Reight::Label.new(
    editable: true, regexp: /^\w+$/)

  def anim_index()             = @anim_index             ||= Reight::Label.new(0, align: CENTER)

  def anim_prev()              = @anim_prev              ||= Reight::Button.new(label: '<')

  def anim_next()              = @anim_next              ||= Reight::Button.new(label: '>')

  def anim_add()               = @anim_add               ||= Reight::Button.new(label: '+')

  def anim_remove()            = @anim_remove            ||= Reight::Button.new(label: '-')

  def anim_image_remove()      = @anim_image_remove      ||= Reight::Button.new(label: '-')

  def anim_images()            = @anim_images            ||= Reight::SpriteEditor::AnimImageList.new

  def canvas()                 = @canvas                 ||= Reight::SpriteEditor::Canvas.new

  def tools()                  = @tools                  ||= @editor.tools.map {|tool|
    Reight::Button.new(name: tool.name, icon: r8.icon(tool.icon_index, 2, 8)).tap do |b|
      b.set_help left: tool.help_text
      b.singleton_class.define_method(:tool) {tool}
    end
  }

  def colors()                 = @colors                 ||=
    @editor.colors.map {Reight::SpriteEditor::Color.new _1}

  def update_layout()
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
      sp.w = @editor.asset_table_page_width  + Reight::AssetTable::PADDING * 2
      sp.h = @editor.asset_table_page_height + Reight::AssetTable::PADDING * 2
    end
    sprite_sizes.map(&:sprite).reverse.map.with_index do |sp, index|
      sp.w = sp.h = app::BUTTON_SIZE
      sp.x        = prev.right - sp.w - (sp.w + space_m) * index
      sp.y        = sprite_table_page_next.sprite.y
    end
    prev = sprite_remove.sprite.tap do |sp|
      sp.w = sp.h = app::BUTTON_SIZE
      sp.x        = sprite_sizes.first.sprite.x - space_l - sp.w
      sp.y        = sprite_sizes.first.sprite.y
    end
    prev = sprite_name.sprite.tap do |sp|
      sp.x = sprite_table.sprite.x
      sp.y = sprite_table.sprite.bottom + space_l
      sp.w = sprite_table.sprite.w
      sp.h = app::BUTTON_SIZE
    end
    prev = anim_prev.sprite.tap do |sp|
      sp.x        = sprite_table.sprite.right + space_l
      sp.y        = sprite_table_page_prev.sprite.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = anim_index.sprite.tap do |sp|
      sp.x        = prev.right + space_s
      sp.y        = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = anim_next.sprite.tap do |sp|
      sp.x        = prev.right + space_s
      sp.y        = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = anim_add.sprite.tap do |sp|
      sp.x        = prev.right + space_s
      sp.y        = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = anim_remove.sprite.tap do |sp|
      sp.x        = prev.right + space_s
      sp.y        = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = anim_image_remove.sprite.tap do |sp|
      sp.w = sp.h = app::BUTTON_SIZE
      sp.x        = width - space_l - sp.w
      sp.y        = prev.y
    end
    prev = anim_name.sprite.tap do |sp|
      sp.x     = anim_remove.sprite.right + space_m
      sp.y     = prev.y
      sp.right = anim_image_remove.sprite.x - space_m
      sp.h     = app::BUTTON_SIZE
    end
    prev = anim_images.sprite.tap do |sp|
      sp.x     = anim_prev.sprite.x
      sp.y     = anim_prev.sprite.bottom + space_m
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
    shift, ctrl, cmd = [SHIFT, CONTROL, COMMAND].map {pressings.include? _1}
    e, se            = @editor, Reight::SpriteEditor
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

end# SpriteEditorInterface
