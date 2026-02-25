class Reight::SoundEditor::Volumes

  extend  Reight::Hookable
  extend  Reight::HasState
  include Reight::Widget

  C = Reight::CONTEXT__
  I = Reight::SoundEditorInterface

  def initialize(editor)
    @editor, @offset = editor, 0
  end

  state :sound
  state :offset, filter: -> n {n.clamp 0..}

  hook :volume_changed

  def draw(sp)
    C.clip sp.x, sp.y, sp.w, sp.h

    C.fill 0
    C.no_stroke
    C.rect 0, 0, sp.w, sp.h

    return unless @sound

    C.translate(-@offset, 0)

    notew = I::NOTE_WIDTH
    @sound.each_note do |note, time_index|
      h = C.map @sound.volume_at(time_index), 0, 1, 0, sp.h
      C.fill 100
      C.stroke 120
      C.rect time_index * notew, sp.h - h, notew, h
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
