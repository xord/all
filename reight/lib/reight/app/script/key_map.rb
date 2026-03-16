class Reight::ScriptEditor::KeyMap

  def initialize(editor, text_editor)
    @editor, @text_editor = editor, text_editor
  end

  def self.commands()
    @commands ||= {}
  end

  def self.command(name, desc: nil, once: false, nosearch: false, &block)
    commands[name] = {block:, desc:, once:, nosearch:}
  end

  command :move_char_forward, nosearch: true do |cursor:, **|
    cursor.col += 1
  end

  command :move_char_backward, nosearch: true do |cursor:, **|
    cursor.col -= 1
  end

  command :move_line_forward, nosearch: true do |cursor:, **|
    cursor.row += 1
  end

  command :move_line_backward, nosearch: true do |cursor:, **|
    cursor.row -= 1
  end

  command :move_to_line_head, nosearch: true do |cursor:, **|
    cursor.col = 0
  end

  command :move_to_line_end, nosearch: true do |cursor:, text:, **|
    cursor.col = text[cursor.row].size
  end

  command :search, once: true do |cursor:, text:, **|
    @searching = '' unless @searching
    search cursor, text, @searching, next: p(@searching.size > 0)
  end

  command :search_forward, once: true do |cursor:, text:, **|
    @searching = '' unless @searching
    search cursor, text, @searching, offset: (@searching.size > 0 ?  1 : 0)
  end

  command :search_backward, once: true do |cursor:, text:, **|
    @searching = '' unless @searching
    search cursor, text, @searching, offset: (@searching.size > 0 ? -1 : 0)
  end

  command :end_search, once: true do |cursor:, text:, **|
    end_searching cursor, text
  end

  def search(cursor, text, str, **options)
    text.clear_attributes :searching
    return if !str || str.empty?
    ranges = []
    text.each.with_index do |line, row|
      line.text.scan str do
        ranges << [row, $~.begin(0).then {_1..(_1 + str.size - 1)}]
      end
    end
    ranges = ranges.sort_by {|row, range| [row, range.begin]}
    if ranges.empty?
      cursor.pos = @last_pos_before_search if @last_pos_before_search
      @last_pos_before_search = nil
      return
    end
    ranges.each do |row, range|
      text[row].apply range, key: :searching, background_color: [150, 150, 100]
    end
    crow, ccol = cursor.pos
    index      = ranges.index {|row, range| row > crow || row == crow && range.begin >= ccol} || 0
    index     += options[:offset] if options[:offset]
    row, range = ranges[index % ranges.size]
    @last_pos_before_search = cursor.pos unless @last_pos_before_search
    cursor.pos              = [row, range.begin]
  end

  def end_searching(cursor, text)
    @searching = nil
    search cursor, text, nil
  end

  def searching?()
    @searching
  end

  command :mark, nosearch: true do |cursor:, **|
    cursor.mark = cursor.index
  end

  command :unmark do |cursor:, **|
    cursor.mark = nil
  end

  command :copy, nosearch: true do |cursor:, **|
    @editor.replace_text cursor.index, cursor.mark - cursor.index, '' if cursor.mark
  end

  command :cut, nosearch: true do |cursor:, **|
    @editor.replace_text cursor.index, cursor.mark - cursor.index, '' if cursor.mark
  end

  command :cut_to_line_end, nosearch: true do |cursor:, text:, **|
    size = text[cursor.row].size - cursor.col
    size = 1 if size == 0
    @editor.replace_text cursor.index, size, ''
  end

  command :paste, nosearch: true do |cursor:, **|
  end

  command :undo, once: true, nosearch: true do |cursor:, **|
    @editor.undo
  end

  command :paste, once: true, nosearch: true do |cursor:, **|
    @editor.redo
  end

  command :input_text, desc: <<~DOC do |str, cursor:, text:, **|
    insert or replace text
  DOC
    if @searching
      @searching << str
      search cursor, text, @searching
    else
      @editor.replace_text(*cursor.selection, str)
    end
  end

  command :delete_char_forward, nosearch: true do |cursor:, **|
    @editor.replace_text(*cursor.selection( 1), '')
  end

  command :delete_char_backward, nosearch: true do |cursor:, **|
    @editor.replace_text(*cursor.selection(-1), '')
  end

  command :add_cursor do |cursor:, text:, **|
    if searching?
      text.map.with_index {|line, row| [row, line]}.to_h
        .transform_values {|line| line.attributes.find_all {_1[:key] == :searching}.map {_1[:range]}.compact}
        .reject {|_, ranges| ranges.empty?}
        .each {|row, ranges| ranges.each {add_cursor cursor, text, [row, _1.begin], true}}
        .then {cursor.active = false unless _1.empty?}
    else
      add_cursor cursor, text, cursor.pos unless
        @text_editor.each_cursor.any? {!_1.equal?(cursor) && _1.pos == cursor.pos}
    end
  end

  def add_cursor(cursor, text, pos, active = false)
    c          = Reight::Text::Cursor.new(text, *pos)
    c.active   = active
    @text_editor.add_cursor c
  end

  command :remove_cursor do |cursor:, **|
    all = @text_editor.each_cursor.to_a.sort
    next if all.size == 1

    index = all.find_index cursor
    all.each {                          _1.active = false}
    all[index > 0 ? index - 1 : index + 1].active = true
  end

  command :clear_cursor, once: true do |cursor:, **|
    @text_editor.each_cursor.to_a.each {@text_editor.remove_cursor _1}
    p @text_editor.each_cursor.map {_1.object_id}
    @text_editor.add_cursor cursor
  end

  command :prev_cursor, once: true, nosearch: true do |cursor:, **|
    activate_cursor(-1)
  end

  command :next_cursor, once: true, nosearch: true do |cursor:, **|
    activate_cursor(+1)
  end

  def activate_cursor(offset)
    all     = @text_editor.each_cursor.to_a.sort
    actives = @text_editor.each_cursor(true).to_a
    index   = (all.find_index(actives.first) + offset) % all.size

    actives.each {_1.active = false}
    all[index]      .active = true
  end

  command :toggle_cursor, once: true do |cursor:, **|
    if @text_editor.each_cursor(true).to_a.size == 1
      @text_editor.each_cursor {_1.active = true}
      @last_cursor = cursor
    else
      @text_editor.each_cursor {_1.active = false}
      (@last_cursor || @text_editor.each_cursor.to_a.first).active = true
    end
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
  map [            [:control, :r    ]],     :search_backward
  map [            [:control, :s    ]],     :search_forward
  map [            [:control, :g    ]], :end_search
  map [            [:control, :space]],   :mark
  map [            [:control, :g    ]], :unmark
  map [:enter,     [:control, :m    ]], :input_text, "\n"
  map [:tab,       [:control, :i    ]], :input_text, "\t"
  map [:backspace, [:control, :h    ]], :delete_char_backward
  map [:delete,    [:control, :d    ]], :delete_char_forward
  map [            [:control, :w    ]], :cut
  map [            [:control, :k    ]], :cut_to_line_end
  map [            [:control, :y    ]], :paste
  map [[:command,         :z]        ], :undo
  map [[:command, :shift, :z]        ], :redo
  map [            [:command, :c    ]],    :add_cursor
  map [            [:command, :d    ]], :remove_cursor
  map [            [:control, :g    ]],  :clear_cursor
  map [            [:command, :p    ]],   :prev_cursor
  map [            [:command, :n    ]],   :next_cursor
  map [            [:command, :t    ]], :toggle_cursor

  def do(command, *args)
    block, once, nosearch =
      self.class.commands[command]&.values_at :block, :once, :nosearch
    raise "command '#{command}' not found" unless block
    active_cursors = @text_editor.each_cursor(true).to_a
    params         = {
      editor: @editor,
      text:   @text_editor.text,
    }
    active_cursors.first&.tap {end_searching _1, _1.text} if nosearch
    active_cursors.each do |cursor|
      next if once && cursor != active_cursors.first
      instance_exec(*args, cursor:, **params, &block)
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
      self.do :input_text, key
      done = true
    end
    @text_editor.redraw_cursors if done
  rescue Reight::Text::NoLineError
  end

end# KeyMap
