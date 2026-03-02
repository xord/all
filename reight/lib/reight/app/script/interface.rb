class Reight::ScriptEditorInterface < Reight::ViewController

  C = Reight::CONTEXT__

  def initialize(editor)
    super

    e = editor
    e.script_changed {text_editor.text = _1.text}

    e.disable_history do
      e.add_script 'game.rb'  if e.scripts.empty?

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
    e, sel = @editor, text_editor.selection
    case C.key_code
    when ENTER     then e.replace_text sel.index,  1, "\n"
    when DELETE    then e.replace_text sel.index,  1, ''
    when BACKSPACE then e.replace_text sel.index, -1, ''
    when UP        then text_editor.row    -= 1
    when DOWN      then text_editor.row    += 1
    when LEFT      then text_editor.column -= 1
    when RIGHT     then text_editor.column += 1
    else                e.replace_text sel.index, 0, C.key if /^[:print]+$/.match?(C.key)
    end
  end

end# ScriptEditorInterface
