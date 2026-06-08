using Reight


class Reight::SoundEditor::PianoRoll

  extend  Reight::Hookable
  extend  Reight::HasState
  include Reight::Widget

  I = Reight::SoundEditorInterface

  def initialize()
    @offset_x = @offset_y = 0
  end

  state :sound
  state :offset_x, filter: -> n {n.clamp 0..}
  state :offset_y, filter: -> n {
    n.clamp 0..((Reight::SoundNote::MAX + 1) * I::NOTE_HEIGHT - sprite.h)
  }

  hook :piano_roll_pressed
  hook :piano_roll_released
  hook :piano_roll_moved
  hook :piano_roll_dragged
  hook :piano_roll_clicked

  hook :note_pressed
  hook :note_released
  hook :note_moved
  hook :note_dragged
  hook :note_clicked

  protected

  def draw(sp)
    @setup_offset__ ||= true.tap do
      self.offset_y = (Reight::SoundNote::MAX * I::NOTE_HEIGHT - sp.h) / 2
    end

    clip sp.x, sp.y, sp.w, sp.h

    no_stroke
    fill 0
    rect 0, 0, sp.w, sp.h

    translate(-@offset_x, -@offset_y)
    draw_grids__
    draw_note_names__
    draw_notes__
    draw_cursor__ sp
  end

  def mouse_pressed(x, y, button)
    return unless @sound
    piano_roll_pressed! x, y, button
    note_pressed!(*note_pos_at__(x, y), button)
  end

  def mouse_released(x, y, button)
    return unless @sound
    piano_roll_released! x, y, button
    note_released!(*note_pos_at__(x, y), button)
  end

  def mouse_moved(x, y)
    super
    return unless @sound
    piano_roll_moved! x, y
    note_moved!(*note_pos_at__(x, y))
  end

  def mouse_dragged(x, y, button)
    return unless @sound
    piano_roll_dragged! x, y, button
    note_dragged!(*note_pos_at__(x, y), button)
  end

  def mouse_clicked(x, y, button)
    return unless @sound
    piano_roll_clicked! x, y, button
    note_clicked!(*p(note_pos_at__(x, y)), button)
  end

  def mouse_wheel(dx, dy)
    self.offset_x = @offset_x - dx
    self.offset_y = @offset_y - dy
  end

  def to_widget(x, y)
    return @offset_x + x, @offset_y + y
  end

  private

  GRID_COLORS       = [100, 80, 60]

  NOTE_INDEX_COLORS = [1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1]
    .map.with_index {|n, i| GRID_COLORS[i == 0 ? 0 : (n == 1 ? 1 : 2)]}

  def draw_grids__()
    sp, notew, noteh, max =
      sprite, I::NOTE_WIDTH, I::NOTE_HEIGHT, Reight::SoundNote::MAX

    no_stroke
    max.downto(0).with_index do |y, index|
      fill NOTE_INDEX_COLORS[index % NOTE_INDEX_COLORS.size]
      rect 0, y * noteh, @offset_x + sp.w, noteh
    end

    no_fill
    (0...(@offset_x + width)).step(notew * 4).with_index do |x, index|
      color = GRID_COLORS[index % 16 == 0 ? 0 : (index % 4 == 0 ? 1 : 2)]
      stroke(*color)
      line x, 0, x, noteh * max
    end
  end

  def draw_notes__()
    notew, noteh, colors, max =
      I::NOTE_WIDTH, I::NOTE_HEIGHT, I::TONE_COLORS, Reight::SoundNote::MAX
    no_stroke
    @sound&.each_note do |note, index|
      x, y    = index * notew, (max - note.index) * noteh
      r, g, b = color(colors[note.tone]).then {[red(_1), green(_1), blue(_1)]}
      fill r, g, b
      rect x, y, notew, noteh
      fill(*[r, g, b].map {(_1 - 50).clamp 0..})
      rect x, y, 1, noteh
    end
  end

  def draw_cursor__(sp)
    return unless mouse_hovered?
    notew, noteh, max = I::NOTE_WIDTH, I::NOTE_HEIGHT, Reight::SoundNote::MAX
    ti, ni            = note_pos_at__ @offset_x + sp.mouse_x, @offset_y + sp.mouse_y
    x, y              = ti * notew, (max - ni) * noteh
    no_stroke
    fill 200, 200, 200, 128
    rect x, y, notew, noteh
  end

  def draw_note_names__()
    no_stroke
    fill 150
    text_size 10
    text_align LEFT, CENTER
    noteh = I::NOTE_HEIGHT
    max   = Reight::SoundNote::MAX
    (0..Reight::SoundNote::MAX).step(12).with_index do |y, index|
      text "C#{index}", 2, (max - y) * noteh, 10, noteh
    end
  end

  def note_pos_at__(x, y)
    notew, noteh, max = I::NOTE_WIDTH, I::NOTE_HEIGHT, Reight::SoundNote::MAX
    time_index        = (x / notew).floor
    note_index        = max - (y / noteh).floor
    [time_index, note_index.clamp(0, max)]
  end

=begin
  def initialize(app)
    @app, @sound = app, app.project.sounds.first
    @scrolly     = NOTE_HEIGHT * Reight::Sound::Note::MAX / 3
  end

  attr_accessor :tone, :tool

  attr_reader :sound

  def sound=(sound)
    @sound = sound
    sound_changed! sound
  end

  def save()
    @app.project.save
  end

  def begin_editing(&block)
    @app.history.begin_grouping
    block.call if block
  ensure
    end_editing if block
  end

  def end_editing()
    @app.history.end_grouping
    save
  end

  def note_pos_at(x, y)
    sp         = sprite
    notew      = sp.w / SEQUENCE_LEN
    max        = Reight::Sound::Note::MAX
    time_index = (x / notew).floor
    note_index = max - ((@scrolly + y) / NOTE_HEIGHT).floor
    return time_index, note_index.clamp(0, max)
  end

  def put(x, y)
    time_i, note_i = note_pos_at x, y

    @sound.each_note(time_index: time_i)
      .select {|note,| (note.index == note_i) != (note.tone == tone)}
      .each   {|note,| remove_note time_i, note.index, note.tone}
    add_note time_i, note_i, tone

    @app.flash note_name y
  end

  def delete(x, y)
    time_i, note_i = note_pos_at x, y
    note           = @sound.at time_i, note_i
    return unless note

    remove_note time_i, note_i, note.tone

    @app.flash note_name y
  end

  def sprite()
    @sprite ||= RubySketch::Sprite.new.tap do |sp|
      pos = -> {return sp.mouse_x, sp.mouse_y}
      sp.draw           {draw}
      sp.mouse_pressed  {mouse_pressed( *pos.call, sp.mouse_button)}
      sp.mouse_released {mouse_released(*pos.call, sp.mouse_button)}
      sp.mouse_moved    {mouse_moved(   *pos.call)}
      sp.mouse_dragged  {mouse_dragged( *pos.call, sp.mouse_button)}
      sp.mouse_clicked  {mouse_clicked( *pos.call, sp.mouse_button)}
    end
  end

  private

  def mouse_pressed(...)
    tool&.canvas_pressed(...)  unless hand?
  end

  def mouse_released(...)
    tool&.canvas_released(...) unless hand?
  end

  def mouse_moved(x, y)
    tool&.canvas_moved(x, y)
    @app.flash note_name y
  end

  def mouse_dragged(...)
    if hand?
      sp        = sprite
      @scrolly -= sp.mouse_y - sp.pmouse_y
    else
      tool&.canvas_dragged(...)
    end
  end

  def mouse_clicked(...)
    tool&.canvas_clicked(...) unless hand?
  end

  def hand? = @app.pressing?(SPACE)

  def note_name(y)
    _, note_i = note_pos_at 0, y
    Reight::Sound::Note.new(note_i).to_s.split(':').first.capitalize
  end
=end
end# PianoRoll
