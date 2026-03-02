class Reight::ScriptEditor < Reight::ModelController

  extend Forwardable
  extend Reight::Hookable
  extend Reight::HasState

  C = Reight::CONTEXT__

  state :script do |new, old|
    @script = new
    group_history do
      append_history [:set_script, new, old]
    end
  end

  attr_reader :script

  def_delegators :@project, :scripts

  def begin_editing(&block)
    history__.begin_grouping
    block.call if block
  ensure
    end_editing if block
  end

  def end_editing()
    history__.end_grouping
  end

  alias edit begin_editing

  def add_script(name, index = nil)
    index = scripts.find_index(@script)&.then {_1 + 1} || scripts.size unless index
    Reight::ScriptAsset.new(@project.get_next_id, 1, 1, name: name).tap do |script|
      scripts.insert index, script
      group_history do
        append_history [:add_script, index, script]
        self.script = script
      end
    end
  end

  def replace_text(index, size, str)
    old = @script.text.replace index, size, str
    return unless old
    append_history [:replace_text, index, str, old]
  end

  def undo()
    history__.undo do |action|
      case action
      in [:set_script, _, old]            then self.script = old
      in [:add_script,   index, script]   then scripts.remove script
      in [:replace_text, index, new, old] then @script.text.replace index, new.size, old
      end
    end
  end

  def redo()
    history__.redo do |action|
      case action
      in [:set_script, new, _]            then self.script = new
      in [:add_script,   index, script]   then scripts.insert index, script
      in [:replace_text, index, new, old] then @script.text.replace index, old.size, new
      end
    end
  end

end# ScriptEditor
