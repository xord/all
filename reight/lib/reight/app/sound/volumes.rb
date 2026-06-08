using Reight


class Reight::SoundEditor::Volumes

  extend  Reight::Hookable
  extend  Reight::HasState
  include Reight::Widget

  I = Reight::SoundEditorInterface

  def initialize(editor)
    @editor, @offset = editor, 0
  end

  state :sound
  state :offset, filter: -> n {n.clamp 0..}

  hook :volume_changed

  def draw(sp)
    clip sp.x, sp.y, sp.w, sp.h

    fill 0
    no_stroke
    rect 0, 0, sp.w, sp.h

    return unless @sound

    translate(-@offset, 0)

    notew = I::NOTE_WIDTH
    @sound.each_note do |note, time_index|
      h = map @sound.volume_at(time_index), 0, 1, 0, sp.h
      fill 100
      stroke 120
      rect time_index * notew, sp.h - h, notew, h
    end
  end

  def mouse_pressed(x, y, button)
    @editor.begin_editing
    update_volume x, y
  end

  def mouse_released(x, y, button)
    @editor.end_editing
  end

  def mouse_dragged(x, y, button)
    update_volume x, y
  end

  def update_volume(x, y)
    sp, notew = sprite, I::NOTE_WIDTH
    volume_changed! ((@offset + x) / notew).to_i, ((sp.h - y) / sp.h.to_f)
  end

end# Volumes
