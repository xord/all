class Reight::ScriptEditorInterface < Reight::ViewController

  C = Reight::CONTEXT__

  def initialize(editor)
    super

    e       = editor
    @keymap = Reight::ScriptEditor::KeyMap.new e, text_editor

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
    @keymap.key_pressed C.key, C.key_code, pressings
  end

end# ScriptEditorInterface


class Reight::ScriptEditor::KeyMap

  def initialize(editor, text_editor)
    @editor, @text_editor = editor, text_editor
  end

  def self.commands()
    @commands ||= {}
  end

  def self.command(name, desc: nil, &block)
    commands[name] = {desc:, block:}
  end

  command :move_char_forward do |cursor:, **|
    cursor.col += 1
  end

  command :move_char_backward do |cursor:, **|
    cursor.col -= 1
  end

  command :move_line_forward do |cursor:, **|
    cursor.row += 1
  end

  command :move_line_backward do |cursor:, **|
    cursor.row -= 1
  end

  command :move_to_line_head do |cursor:, **|
    cursor.col = 0
  end

  command :move_to_line_end do |cursor:, text:, **|
    cursor.col = text[cursor.row].size
  end

  command :mark do |cursor:, text:, **|
    cursor.mark = cursor.index
  end

  command :unmark do |cursor:, text:, **|
    cursor.mark = nil
  end

  command :cut_to_line_end do |cursor:, text:, **|
    size = text[cursor.row].size - cursor.col
    size = 1 if size == 0
    @editor.replace_text cursor.index, size, ''
  end

  command :replace_text, desc: <<~DOC do |str, cursor:, **|
    insert or replace text
  DOC
    @editor.replace_text(*cursor.selection, str)
  end

  command :delete_char_forward do |cursor:, **|
    @editor.replace_text(*cursor.selection( 1), '')
  end

  command :delete_char_backward do |cursor:, **|
    @editor.replace_text(*cursor.selection(-1), '')
  end

  command :add_cursor do |cursor:, text:, **|
    @text_editor.add_cursor Reight::ScriptEditor::TextEditor::Cursor.new(text, *cursor.pos)
  end

  command :clear_cursor do
    @text_editor.cursor = @text_editor.cursor
  end

  def self.keymap()
    @keymap ||= {}
  end

  def self.map(keys, command, *args)
    keys.each do |key|
      (keymap[Set.new [key].flatten] ||= []) << {command:, args:}
    end
  end

  map [:left,      [:control, :b    ]], :move_char_backward
  map [:right,     [:control, :f    ]], :move_char_forward
  map [:up,        [:control, :p    ]], :move_line_backward
  map [:down,      [:control, :n    ]], :move_line_forward
  map [:home,      [:control, :a    ]], :move_to_line_head
  map [:end,       [:control, :e    ]], :move_to_line_end
  map [            [:control, :space]],   :mark
  map [            [:control, :g    ]], :unmark
  map [:enter,     [:control, :m    ]], :replace_text, "\n"
  map [:tab,       [:control, :i    ]], :replace_text, "\t"
  map [:backspace, [:control, :h    ]], :delete_char_backward
  map [:delete,    [:control, :d    ]], :delete_char_forward
  map [            [:control, :w    ]], :cut
  map [            [:control, :k    ]], :cut_to_line_end
  map [            [:control, :y    ]], :paste
  map [            [:control, :c    ]],   :add_cursor
  map [            [:control, :g    ]], :clear_cursor

  def do(command, *args)
    block = self.class.commands[command]&.fetch :block, nil
    raise "command '#{command}' not found" unless block
    @text_editor.cursors[0, 1].each do |cursor|
      instance_exec(*args, editor: @editor, text: @text_editor.text, cursor:, &block)
    end
  end

  def key_pressed(key, code, pressings)
    mods     = [:shift, :control, :command].select {pressings.include? _1}
    keymap   = self.class.keymap
    commands = [[key, *mods], [code, *mods]].map {keymap[Set.new _1]}.compact.flatten

    done = false
    commands.each do |command|
      cmd, args = command.fetch_values :command, :args
      self.do cmd, *args
      done = true
    end
    if !done && key&.match?(/^[[:print:]]+$/)
      self.do :replace_text, key
      done = true
    end
    @text_editor.redraw_cursors if done
  rescue Reight::Text::NoLineError
  end

end# KeyMap
