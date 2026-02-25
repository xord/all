class Reight::SoundEditor::MiniMap

  extend  Reight::Hookable
  extend  Reight::HasState
  include Reight::Widget

  C = Reight::CONTEXT__
  I = Reight::SoundEditorInterface

  def initialize()
    @offset = 0
  end

  state :sound
  state :offset, filter: -> n {n.clamp 0..}

  def draw(sp)
    C.clip sp.x, sp.y, sp.w, sp.h

    C.fill 0
    C.no_stroke
    C.rect 0, 0, sp.w, sp.h

    sx, sy = 1 / I::NOTE_WIDTH.to_f, sprite.h / Reight::SoundNote::MAX.to_f

    C.fill 100
    C.rect @offset * sx, 1, sp.w * sx, sp.h - 2

    colors = Reight::SoundEditorInterface::TONE_COLORS
    @sound&.each_note do |note, time_index|
      C.fill colors[note.tone]
      C.rect time_index, sp.h - (note.index * sy), 1, 1
    end
  end

  def mouse_pressed(x, y, button)
    @start_x      = x
    @start_offset = @offset
  end

  def mouse_dragged(x, y, button)
    self.offset = @start_offset + (x - @start_x) * I::NOTE_WIDTH
  end

end# MiniMap
