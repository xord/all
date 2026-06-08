using Reight


class Reight::ScriptEditorInterface < Reight::ViewController

  def initialize(editor)
    super

    @keymap = Reight::ScriptEditor::KeyMap.new editor, text_editor

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
      sp.right  = width
      sp.bottom = height
    end
  end

  def key_pressed(pressings)
    @keymap.key_pressed key, key_code, pressings
  end

end# ScriptEditorInterface
