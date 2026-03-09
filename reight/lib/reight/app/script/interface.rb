class Reight::ScriptEditorInterface < Reight::ViewController

  C = Reight::CONTEXT__

  def initialize(editor)
    super

    e = editor
    e.script_changed {text_editor.text = _1.text}

    e.disable_history do
      e.add_script 'game.rb' if e.scripts.empty?
      e.script = e.scripts.first
    end
  end

  def sprites()
    [text_editor].map(&:sprite)
  end

  def text_editor = @text_editor ||= Reight::ScriptEditor::TextEditor.new

  def update_layout()
    app = Reight::App

    text_editor.sprite.tap do |sp|
      sp.x      = 0
      sp.y      = app::NAVIGATOR_HEIGHT
      sp.right  = C.width
      sp.bottom = C.height
    end
  end

  def key_pressed(pressings)
    #shift, ctrl, cmd = [SHIFT, CONTROL, COMMAND].map {pressings.include? _1}
    e = @editor
    text_editor.cursors.each do |c|
      case C.key_code
      when ENTER     then e.replace_text(*c.selection,   "\n")
      when DELETE    then e.replace_text(*c.selection( 1), '')
      when BACKSPACE then e.replace_text(*c.selection(-1), '')
      when ESC       then text_editor.cursor = text_editor.cursor
      when UP        then c.row -= 1
      when DOWN      then c.row += 1
      when LEFT      then c.col -= 1
      when RIGHT     then c.col += 1
      else e.replace_text(*c.selection, C.key) if C.key&.match?(/^[[:print:]]+$/)
      end
    end
    text_editor.redraw_cursors
  rescue Reight::Text::NoLineError
  end

end# ScriptEditorInterface
