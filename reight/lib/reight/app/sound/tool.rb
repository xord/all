class Reight::SoundEditor::Tool < Reight::EditorTool

  def piano_roll_pressed( x, y, button) = nil
  def piano_roll_released(x, y, button) = nil
  def piano_roll_moved(   x, y)         = nil
  def piano_roll_dragged( x, y, button) = nil
  def piano_roll_clicked( x, y, button) = nil

  def note_pressed( time_index, note_index, button) = nil
  def note_released(time_index, note_index, button) = nil
  def note_moved(   time_index, note_index)         = nil
  def note_dragged( time_index, note_index, button) = nil
  def note_clicked( time_index, note_index, button) = nil

end# Tool
