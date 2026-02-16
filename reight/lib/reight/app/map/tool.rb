class Reight::MapEditor::Tool

  def initialize(editor)
    @editor = editor
  end

  attr_reader :editor

  def name = self.class.name.split('::').last

  def canvas_pressed( x, y, button) = nil
  def canvas_released(x, y, button) = nil
  def canvas_moved(   x, y)         = nil
  def canvas_dragged( x, y, button) = nil
  def canvas_clicked( x, y, button) = nil

end# Tool
