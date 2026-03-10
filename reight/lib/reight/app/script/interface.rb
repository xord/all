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

  command :cut_to_line_end do |cursor:, text:, **|
    size = text[cursor.row].size - cursor.col
    size = 1 if size == 0
    @editor.replace_text cursor.index, size, ''
  end

  command :cursor_clear do
    @text_editor.cursor = @text_editor.cursor
  end

  def self.keymap()
    @keymap ||= {}
  end

  def self.map(key, command, *args)
    keymap[Set.new [key].flatten] = [command, args]
  end

  map :enter,     :replace_text, "\n"
  map :tab,       :replace_text, "\t"
  map :backspace, :delete_char_backward
  map :delete,    :delete_char_forward
  map :left,      :move_char_backward
  map :right,     :move_char_forward
  map :up,        :move_line_backward
  map :down,      :move_line_forward
  map :home,      :move_to_line_head
  map :end,       :move_to_line_end
  map :escape,    :cursor_clear

  map [:m, :control], :replace_text, "\n"
  map [:i, :control], :replace_text, "\t"
  map [:b, :control], :move_char_backward
  map [:f, :control], :move_char_forward
  map [:p, :control], :move_line_backward
  map [:n, :control], :move_line_forward
  map [:a, :control], :move_to_line_head
  map [:e, :control], :move_to_line_end
  map [:h, :control], :delete_char_backward
  map [:d, :control], :delete_char_forward
  map [:k, :control], :cut_to_line_end

  def do(command, *args)
    block = self.class.commands[command]&.fetch(:block, nil) || return
    @text_editor.cursors[0, 1].each do |cursor|
      instance_exec *args, editor: @editor, text: @text_editor.text, cursor:, &block
    end
  end

  def key_pressed(key, code, pressings)
    mods          = [:shift, :control, :command].select {pressings.include? _1}
    keymap        = self.class.keymap
    command, args = [[key, *mods], [code, *mods], [key], [code]]
      .lazy.filter_map {keymap[Set.new _1]}.first

    if command
      self.do command, *args
    elsif key&.match?(/^[[:print:]]+$/)
      self.do :replace_text, key
    else
      return
    end
    @text_editor.redraw_cursors
  rescue Reight::Text::NoLineError
  end

end# KeyMap
