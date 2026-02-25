class Reight::SoundEditor < Reight::ModelController

  extend Forwardable
  extend Reight::Hookable
  extend Reight::HasState

  C = Reight::CONTEXT__

  state :sound do |new, old|
    @sound = new
    group_history do
      append_history [:set_sound, new, old]
    end
  end

  state :tool
  state :tone

  attr_reader :sound, :tool, :tone

  def_delegators :@project, :sounds

  def_delegators :@settings,
    :asset_table_width,
    :asset_table_height,
    :asset_table_page_width,
    :asset_table_page_height

  def tools() = @tools ||= [
    Reight::SoundEditor::Brush .new(self),
    Reight::SoundEditor::Eraser.new(self)
  ]

  def tones() = Reight::SoundNote::TONES

  def begin_editing(&block)
    history__.begin_grouping
    block.call @sound if block
  ensure
    end_editing if block
  end

  def end_editing()
    history__.end_grouping
  end

  def add_sound(x, y, w, h)
    Reight::SoundAsset.new(@project.get_next_id, w, h, x, y).tap do |s|
      group_history do
        sounds.put s
        append_history [:add_sound, s]
        self.sound = s
      end
    end
  end

  def remove_sound()
    return nil unless @sound
    sound, index = @sound, sounds.find_index(@sound)
    group_history do
      sounds.remove sound
      append_history [:remove_sound, sound]
      self.sound = sounds[index] || sounds[-1]
    end
  end

  def set_sound_name(name)
    old, @sound.name = @sound.name, name
    append_history [:set_sound_name, name, old]
  end

  def set_sound_bpm(bpm)
    bpm = bpm.to_i.clamp 0, Reight::SoundAsset::BPM_MAX
    old, @sound.bpm = @sound.bpm, bpm
    append_history [:set_sound_bpm, bpm, old]
  end

  def put_note(time_index, note_index)
    return unless @sound && @tone
    ti, ni = time_index, note_index
    return nil if @sound.at(ti, ni)&.tone == @tone
    @sound.add ti, ni, @tone
    @sound.at(ti, ni)&.play 120
    append_history [:put_note, ti, ni, @tone]
  end

  def remove_note(time_index, note_index)
    return nil unless @sound && @tone
    ti, ni = time_index, note_index
    @sound.at(ti, ni)&.tap do |note|
      #note&.play @sound.bpm
      @sound.remove ti, ni
      append_history [:remove_note, ti, ni, note.tone]
    end
  end

  def set_volume(time_index, volume)
    return unless @sound
    old = @sound.set_volume time_index, volume
    append_history [:set_volume, time_index, volume, old] if volume != old
  end

  def undo()
    history__.undo do |action|
      case action
      in [:set_sound,      _, old]    then self.sound      = old
      in [:set_sound_name, _, old]    then self.sound.name = old
      in [:set_sound_bpm,  _, old]    then self.sound.bpm  = old
      in [   :add_sound, sound]       then sounds.remove sound
      in [:remove_sound, sound]       then sounds.put    sound
      in [   :put_note, ti, ni, _]    then @sound.remove ti, ni
      in [:remove_note, ti, ni, tone] then @sound.add    ti, ni, tone
      in [:set_volume, ti, _, old]    then @sound.set_volume ti, old
      end
    end
  end

  def redo()
    history__.redo do |action|
      case action
      in [:set_sound,      new, _]    then self.sound      = new
      in [:set_sound_name, new, _]    then self.sound.name = new
      in [:set_sound_bpm,  new, _]    then self.sound.bpm  = new
      in [   :add_sound, sound]       then sounds.put    sound
      in [:remove_sound, sound]       then sounds.remove sound
      in [   :put_note, ti, ni, tone] then @sound.add    ti, ni, tone
      in [:remove_note, ti, ni, _]    then @sound.remove ti, ni
      in [:set_volume, ti, new, _]    then @sound.set_volume ti, new
      end
    end
  end

=begin
  def canvas()
    @canvas ||= Canvas.new self
  end

  def setup()
    super
    history.disable do
      tones[0].click
      tools[0].click
    end
  end

  def key_pressed()
  end

  def window_resized()
    super
    index.sprite.tap do |sp|
      sp.w, sp.h = 32, BUTTON_SIZE
      sp.x       = SPACE
      sp.y       = NAVIGATOR_HEIGHT + SPACE
    end
    bpm.sprite.tap do |sp|
      sp.w, sp.h = 40, BUTTON_SIZE
      sp.x       = index.sprite.right + SPACE
      sp.y       = index.sprite.y
    end
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
    tools.map(&:sprite).each.with_index do |sp, i|
      sp.w = sp.h = BUTTON_SIZE
      sp.x        = controls.last.sprite.right + SPACE * 2 + (sp.w + 1) * i
      sp.y        = controls.last.sprite.y
    end
    tones.map(&:sprite).each.with_index do |sp, i|
      sp.w = sp.h = BUTTON_SIZE
      sp.x        = tools.last.sprite.right + SPACE * 2 + (sp.w + 1) * i
      sp.y        = tools.last.sprite.y
    end
    canvas.sprite.tap do |sp|
      sp.x      = SPACE
      sp.y      = index.sprite.bottom + SPACE
      sp.right  = width  - SPACE
      sp.bottom = tools.first.sprite.y - SPACE
    end
  end

  private

  def sprites()
    [index, bpm, *edits, *controls, *tools, *tones, canvas]
      .map(&:sprite) + super
  end

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

  def tones()
    @tones ||= group(*Reight::Sound::Note::TONES.map.with_index {|tone, index|
      name  = tone.to_s.capitalize.gsub('_', '.')
      name += ' Wave' if name !~ /noise/i
      color = Canvas::TONE_COLORS[tone]
      Reight::Button.new name: name, icon: icon(index, 3, 8) do
        canvas.tone = tone
        Reight::Sound::Note.new(60, tone).play 120 if active?
      end.tap do |b|
        b.instance_variable_set :@color, color
        class << b
          alias draw_ draw
          def draw
            draw_
            no_fill
            stroke @color
            stroke_weight 1
            w, h = sprite.width, sprite.height
            line 3, h - 1, w - 3, h - 1
          end
        end
      end
    })
  end
=end
end# SoundEditor
