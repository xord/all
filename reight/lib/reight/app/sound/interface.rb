using Reight


class Reight::SoundEditorInterface < Reight::AppInterface

  NOTE_WIDTH  = 10
  NOTE_HEIGHT = 3

  TONE_COLORS = {
    sine:      5,
    triangle:  29,
    square:    19,
    sawtooth:  30,
    pulse12_5: 27,
    pulse25:   14,
    noise:     12
  }.transform_values {Reight::App::PALETTE_COLORS[_1]}

  def initialize(editor, navigator)
    super

    e = editor
    e.sound_changed {sound_changed _1, _2}
    e.tool_changed  {|tool| tools.each {_1.active = _1.tool == tool}}
    e.tone_changed  {|tone| tones.each {_1.active = _1.tone == tone}}

    sound_table.selected           {e.sound = _1}
    sound_table.add_asset          {|x, y, w, h| e.add_sound x, y, w,h}
    sound_table.page_changed       {sound_table_page.value = _1}
    sound_table_page_prev.enabled? {sound_table.page  > 0}
    sound_table_page_prev.clicked  {sound_table.page -= 1}
    sound_table_page_next.enabled? {sound_table.page  < sound_table.npages - 1}
    sound_table_page_next.clicked  {sound_table.page += 1}
    sound_remove.clicked           {e.remove_sound}
    sound_name.changed             {e.set_sound_name _1}
    sound_bpm.changed              {bpm_changed _1}
    play_or_stop.clicked           {e.sound&.tap {_1.playing? ? _1.stop : _1.play}}
    mini_map  .offset_changed      {offset_changed _1}
    piano_roll.offset_x_changed    {offset_changed _1}
    volumes   .offset_changed      {offset_changed _1}
    volumes.volume_changed         {|*a| e.set_volume(*a)}

    piano_roll.piano_roll_pressed  {|*a| e.tool&.piano_roll_pressed(*a)}
    piano_roll.piano_roll_released {|*a| e.tool&.piano_roll_released(*a)}
    piano_roll.piano_roll_moved    {|*a| e.tool&.piano_roll_moved(*a)}
    piano_roll.piano_roll_dragged  {|*a| e.tool&.piano_roll_dragged(*a)}
    piano_roll.piano_roll_clicked  {|*a| e.tool&.piano_roll_clicked(*a)}
    piano_roll.note_pressed        {|*a| e.tool&.note_pressed(*a)}
    piano_roll.note_released       {|*a| e.tool&.note_released(*a)}
    piano_roll.note_moved          {|*a| e.tool&.note_moved(*a)}
    piano_roll.note_dragged        {|*a| e.tool&.note_dragged(*a)}
    piano_roll.note_clicked        {|*a| e.tool&.note_clicked(*a)}

    tools.each {|button| button.clicked {e.tool = button.tool}}
    tones.each {|button| button.clicked {tone_clicked button.tone}}

    e.disable_history do
      sound_table.assets = e.sounds
      e.tool             = e.tools.first
      e.tone             = e.tones.first

      e.add_sound 0, 0, *sound_table.size_for_new_asset if e.sounds.empty?
    end
  end

  def sound_changed(sound, old)
    sound_table.select sound
    mini_map  .sound = sound
    piano_roll.sound = sound
    volumes   .sound = sound

    bind __method__, sound, old do
      sound_name.value = sound&.name
      sound_bpm.value  = sound&.bpm
    end
  end

  def bpm_changed(bpm)
    editor.set_sound_bpm bpm
  rescue ArgumentError
    self.bpm.value = editor.sound.bpm
  end

  def offset_changed(offset)
    mini_map  .offset   = offset
    piano_roll.offset_x = offset
    volumes   .offset   = offset
  end

  def tone_clicked(tone)
    editor.tone = tone
    Reight::SoundNote.new(60, tone).play 120
  end

  def sprites()
    super + [
      sound_table_page_prev,
      sound_table_page,
      sound_table_page_next,
      sound_table,
      sound_remove,
      sound_name,
      sound_bpm,
      play_or_stop,
      *tools,
      *tones,
      mini_map,
      piano_roll,
      volumes
    ].map(&:sprite)
  end

  def sound_table()           = @sound_table           ||= Reight::AssetTable.new(
    editor.asset_table_width,      editor.asset_table_width,
    editor.asset_table_page_width, editor.asset_table_page_height,
    size_for_new_asset: 16)

  def sound_table_page()      = @sound_table_page      ||= Reight::Label.new(0, align: CENTER)

  def sound_table_page_prev() = @sound_table_page_prev ||= Reight::Button.new(label: '<')

  def sound_table_page_next() = @sound_table_page_next ||= Reight::Button.new(label: '>')

  def sound_remove()          = @sound_remove          ||= Reight::Button.new(label: '-')

  def sound_name()            = @sound_name            ||= Reight::Label.new(
    editable: true, prefix: 'Name: ', regexp: /^\w+$/)

  def sound_bpm()             = @sound_bpm             ||= Reight::Label.new(
    editable: true, prefix: 'BPM: ', regexp: /^\-?\d+$/)

  def clear_all_notes()       = @clear_all_notes       ||= Reight::Button.new(
    name: 'Clear All Notes', label: 'Clear')

  def delete_sound()          = @delete_sound          ||= Reight::Button.new(
    name: 'Delete Sound',    label: 'Delete')

  def play_or_stop()          = @play_or_stop          ||= Reight::Button.new(
    name: 'Play Sound',      label: 'Play')

  def mini_map()              = @mini_map              ||= Reight::SoundEditor::MiniMap.new

  def piano_roll()            = @piano_roll            ||= Reight::SoundEditor::PianoRoll.new

  def volumes()               = @volumes               ||= Reight::SoundEditor::Volumes.new(editor)

  def tools()                 = @tools                 ||= editor.tools.map {|tool|
    Reight::Button.new(name: tool.name, icon: r8.icon(tool.icon_index, 2, 8)).tap do |b|
      b.set_help left: tool.help_text
      b.singleton_class.define_method(:tool) {tool}
    end
  }

  def tones()                 = @tones                 ||= editor.tones.map.with_index {|tone, index|
    name  = tone.to_s.capitalize.gsub('_', '.')
    name += ' Wave' if name !~ /noise/i
    color = TONE_COLORS[tone]
    Reight::Button.new(name: name, icon: r8.icon(index, 3, 8)).tap do |b|
      b.set_help left: name
      b.singleton_class.define_method(:tone) {tone}
    end.tap do |b|
      b.instance_variable_set :@color, color
      class << b
        alias draw_ draw
        def draw(sp)
          draw_ sp
          no_fill
          stroke @color
          stroke_weight 1
          w, h = sprite.width, sprite.height
          line 3, h - 1, w - 3, h - 1
        end
      end
    end
  }

  def update_layout()
    super

    app                       = Reight::App
    space_l, space_m, space_s = app::SPACE, app::SPACE / 2, 1

    prev = sound_table_page_prev.sprite.tap do |sp|
      sp.x        = space_l
      sp.y        = app::NAVIGATOR_HEIGHT + space_l
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = sound_table_page.sprite.tap do |sp|
      sp.x        = prev.right + space_s
      sp.y        = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = sound_table_page_next.sprite.tap do |sp|
      sp.x        = prev.right + space_s
      sp.y        = prev.y
      sp.w = sp.h = app::BUTTON_SIZE
    end
    prev = sound_table.sprite.tap do |sp|
      sp.x = sound_table_page_prev.sprite.x
      sp.y = sound_table_page_prev.sprite.bottom + space_m
      sp.w = editor.asset_table_page_width  + Reight::AssetTable::PADDING * 2
      sp.h = editor.asset_table_page_height + Reight::AssetTable::PADDING * 2
    end
    prev = sound_remove.sprite.tap do |sp|
      sp.w = sp.h = app::BUTTON_SIZE
      sp.x        = prev.right - sp.w
      sp.y        = sound_table_page_next.sprite.y
    end
    prev = sound_name.sprite.tap do |sp|
      sp.x = sound_table.sprite.x
      sp.y = sound_table.sprite.bottom + space_l
      sp.w = sound_table.sprite.w
      sp.h = app::BUTTON_SIZE
    end
    prev = sound_bpm.sprite.tap do |sp|
      sp.x = prev.x
      sp.y = prev.bottom + space_m
      sp.w = prev.w
      sp.h = prev.h
    end
    prev = play_or_stop.sprite.tap do |sp|
      sp.x       = sound_table.sprite.right + space_l
      sp.y       = sound_table_page_prev.sprite.y
      sp.w, sp.h = 32, app::BUTTON_SIZE
    end
    prev = mini_map.sprite.tap do |sp|
      sp.x     = prev.x
      sp.y     = prev.bottom + space_m
      sp.right = width - space_l
      sp.h     = 10
    end
    tools.map(&:sprite).each.with_index do |sp, index|
      sp.w = sp.h = app::BUTTON_SIZE
      sp.x        = play_or_stop.sprite.x + (sp.w + space_s) * index
      sp.y        = height - space_l - sp.h
    end
    tones.map(&:sprite).each.with_index do |sp, index|
      sp.w = sp.h = app::BUTTON_SIZE
      sp.x        = tools.last.sprite.right + space_l + (sp.w + space_s) * index
      sp.y        = tools.last.sprite.y
    end
    prev = volumes.sprite.tap do |sp|
      sp.w = mini_map.sprite.w
      sp.h = 16
      sp.x = tools.first.sprite.x
      sp.y = tools.first.sprite.y - space_m - sp.h
    end
    prev = piano_roll.sprite.tap do |sp|
      sp.x      = mini_map.sprite.x
      sp.y      = mini_map.sprite.bottom + space_m
      sp.w      = mini_map.sprite.w
      sp.bottom = volumes.sprite.y - space_m
    end
=begin
    edits.map(&:sprite).each.with_index do |sp, i|
      sp.w, sp.h = 32, BUTTON_SIZE
      sp.x       = bpm.sprite.right + SPACE + (sp.w + 1) * i
      sp.y       = bpm.sprite.y
    end
    controls.map(&:sprite).each.with_index do |sp, i|
      sp.w, sp.h = 32, BUTTON_SIZE
      sp.x       = SPACE + (sp.w + 1) * i
      sp.y       = height - (SPACE + sp.h)
    end
=end
  end

  def key_pressed(pressings)
    super

    case key_code
    when ENTER then play_or_stop.click
    #when :b    then  brush.click
    #when :e    then eraser.click
    #when /^[#{(1..Reight::Sound::Note::TONES.size).to_a.join}]$/
    #  tones[key_code.to_s.to_i - 1].click
    end
  end
=begin

  def setup()
    super
    history.disable do
      tones[0].click
      tools[0].click
    end
  end

  def key_pressed()
    super
    case key_code
    when ENTER then play_or_stop.click
    when :b    then  brush.click
    when :e    then eraser.click
    when /^[#{(1..Reight::Sound::Note::TONES.size).to_a.join}]$/
      tones[key_code.to_s.to_i - 1].click
    end
  end

  private

  def index()
    @index ||= Reight::Index.new do |index|
      canvas.sound = project.sounds[index] ||= Reight::Sound.new
    end
  end

  def bpm()
    @bpm ||= Reight::Text.new(
      canvas.sound.bpm, label: 'BPM ', regexp: /^\-?\d+$/, editable: true
    ) do |str, text|
      bpm = str.to_i.clamp(0, Reight::Sound::BPM_MAX)
      next text.revert if bpm <= 0
      text.value = canvas.sound.bpm = bpm
      canvas.save
    end.tap do |text|
      canvas.sound_changed {text.value = _1.bpm}
    end
  end

  def edits()
    @edits ||= [
      Reight::Button.new(name: 'Clear All Notes', label: 'Clear') {
        canvas.sound.clear
        canvas.save
      },
      Reight::Button.new(name: 'Delete Sound', label: 'Delete') {
        project.sounds.delete_at index.index
        canvas.sound = project.sounds[index.index] ||= Reight::Sound.new
        canvas.save
      },
    ]
  end

  def controls()
    @controls ||= [play_or_stop]
  end

  def play_or_stop()
    @play_or_stop ||= Reight::Button.new(name: 'Play Sound', label: 'Play') {|b|
      played  = -> {b.name, b.label = 'Stop Sound', 'Stop'}
      stopped = -> {b.name, b.label = 'Play Sound', 'Play'}
      if canvas.sound.playing?
        canvas.sound.stop
        stopped.call
      else
        canvas.sound.play {stopped.call}
        played.call
      end
    }
  end

  def tools()
    @tools ||= group brush, eraser
  end

  def brush  = @brush  ||= Brush.new(self)  {canvas.tool = _1}
  def eraser = @eraser ||= Eraser.new(self) {canvas.tool = _1}

=end
end# SoundEditorInterface
