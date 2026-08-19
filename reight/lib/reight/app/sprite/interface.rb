using Reight


class Reight::SpriteEditorInterface < Reight::AppInterface

  SPRITE_SIZES = [8, 16, 32]

  def update_layout()
    app     = Reight::App
    button  = app::BUTTON_SIZE
    table_w = editor.asset_table_page_width  + Reight::AssetTable::PADDING * 2
    table_h = editor.asset_table_page_height + Reight::AssetTable::PADDING * 2

    layout space: app::SPACE do
      row h: :fill, pad: app::SPACE, gap: app::SPACE do
        column w: table_w do
          row h: button, gap: 1 do
            put :sprite_table_page_prev, Button(label: '<'),       w: button
            put :sprite_table_page,      Label(0, align: CENTER),  w: button
            put :sprite_table_page_next, Button(label: '>'),       w: button
            spacer
            put :sprite_remove, Button(label: '-'),                w: button
            space_l(-2)
            put :sprite_size,   Button(label: editor.sprite_size), w: button
          end
          space_m
          put :sprite_table, -> {
            Reight::AssetTable.new(
              editor.asset_table_width,      editor.asset_table_width,
              editor.asset_table_page_width, editor.asset_table_page_height)
          }, h: table_h
          space_m
          put :sprite_name, Label(
            prefix: 'Name: ', editable: true, regexp: /^\w+$/
          ), h: button
        end

        column w: :fill do
          row h: button, gap: 1 do
            put :anim_prev,  Button(label: '<'),        w: button
            put :anim_index, Label(0, align: CENTER),   w: button
            put :anim_next,  Button(label: '>'),        w: button
            space_m
            put :anim_name,         Label(editable: true, regexp: /^\w+$/)
            put :anim_image_remove, Button(label: '-'), w: button
          end
          space_m
          put :anim_images, -> {
            Reight::SpriteEditor::AnimImageList.new
          }, h: 32 + Reight::SpriteEditor::AnimImageList::PADDING * 2
          space_l
          row h: :fill do
            spacer
            column gap: 1 do
              spacer
              tools.each {put _1, w: button, h: button}
              spacer
            end
            space_l
            put :canvas, -> {Reight::SpriteEditor::Canvas.new}, aspect: 1
            space_l
            column do
              spacer
              grid rows: 8 do
                colors.each {put _1, w: (button * 0.8).floor, h: button}
              end
              spacer
            end
            spacer
          end
        end
      end
    end

    layout_popup do
      base = sprite_size.sprite
      sprite_sizes.each.with_index do |b, index|
        index -= SPRITE_SIZES.index(editor.sprite_size)
        put b, at: [base.x + (base.w + (app::SPACE / 2)) * index, base.y], w: button, h: button
      end
    end
  end

  def sprite_sizes() = @sprite_sizes ||=
    SPRITE_SIZES.map {Reight::Button.new(label: _1, shadow: 1)}

  def tools()        = @tools        ||= editor.tools.map {|tool|
    Reight::Button.new(name: tool.name, icon: r8.icon(tool.icon_index, 2, 8)).tap do |b|
      b.set_help left: tool.help_text
      b.singleton_class.define_method(:tool) {tool}
    end
  }

  def colors()       = @colors       ||=
    editor.colors.map {Reight::SpriteEditor::Color.new _1}

  def setup_handlers()
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

    anim_prev.enabled? {e.anim_index&.then {_1 > 0}}
    anim_prev.clicked  {e.anim_index -= 1}
    anim_next.enabled? {e.anim_index&.then {_1 < e.sprite.size - 1}}
    anim_next.clicked  {e.anim_index += 1}

    anim_name.changed               {e.set_anim_name _1}
    anim_image_remove.clicked       {e.remove_anim_image}
    anim_images.selected            {e.anim_image = _1}
    anim_images.add_image           {e.add_anim_image _1}

    canvas.canvas_pressed  {|*a| e.tool&.canvas_pressed(*a)}
    canvas.canvas_released {|*a| e.tool&.canvas_released(*a)}
    canvas.canvas_moved    {|*a| e.tool&.canvas_moved(*a)}
    canvas.canvas_dragged  {|*a| e.tool&.canvas_dragged(*a)}
    canvas.canvas_clicked  {|*a| e.tool&.canvas_clicked(*a)}

    sprite_sizes.each {|button| button.clicked {e.sprite_size = button.label; close_popup}}
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

  def select_sprite_size()
    popup sprite_sizes
    sprite_sizes.each do |b|
      x, b.sprite.x = b.sprite.x, sprite_size.sprite.x
      animate_value(0.2, from: b.sprite.x, to: x) {b.sprite.x = _1}
    end
  end

  def sprite_size_changed(size)
    sprite_size.label = size
    sprite_table.size_for_new_asset = size
  end

  def anim_changed(anim, old)
    anim_index.value = editor.anim_index
    anim_images.anim = anim
    bind(__method__, anim, old) {anim_name.value = anim&.name}
  end

  def anim_image_changed(image, old)
    anim_images.select image
    canvas.image = image
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

end# SpriteEditorInterface
