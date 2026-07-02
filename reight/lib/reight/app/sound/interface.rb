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
    app     = Reight::App
    button  = app::BUTTON_SIZE
    table_w = editor.asset_table_page_width  + Reight::AssetTable::PADDING * 2
    table_h = editor.asset_table_page_height + Reight::AssetTable::PADDING * 2

    layout do
      row h: :fill, pad: app::SPACE, gap: app::SPACE do
        column w: table_w do
          row h: button, gap: 1 do
            put sound_table_page_prev, w: button
            put sound_table_page,      w: button
            put sound_table_page_next, w: button
            spacer
            put sound_remove, w: button
          end
          space app::SPACE / 2
          put sound_table, h: table_h
          space app::SPACE
          put sound_name, h: button
          space app::SPACE / 2
          put sound_bpm,  h: button
        end
        column w: :fill do
          row h: button do
            put play_or_stop, w: 32
          end
          space app::SPACE / 2
          put mini_map, h: 10
          space app::SPACE / 2
          put piano_roll
          space app::SPACE / 2
          put volumes, h: 16
          space app::SPACE / 2
          row h: button, gap: 1 do
            tools.each {put _1, w: button}
            space app::SPACE - 2
            tones.each {put _1, w: button}
          end
        end
      end
    end
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
