class Reight::ScriptAsset < Reight::Asset

  include Xot::Inspectable

  def self.load(state, project)
    Reight::Editable.load Reight::ScriptAsset, state:, project:
  end

  def initialize(*args, name: nil, load: nil)
    super(*args, name: name, load: load)
    if load
      project, = load.fetch_values :project
      @text = Reight::Text.new load_script__(project)
    else
      @text = Reight::Text.new
    end

    @text.set_parent self
  end

  def save(proj)
    save_script__ proj
    super.merge(text: @text.save(proj))
  end

  protected def state_variables() = super.merge(text:)

  attr_reader :text

  def path(project)
    name  = self.name.to_s
    name += '.rb' unless name.end_with? '.rb'
    project.path_for name
  end

  private

  def save_script__(project)
    File.write path(project), @text.to_s if @text.modified?
  end

  def load_script__(project)
    path = self.path project
    return nil unless File.exist? path
    File.read path
  end

end# ScriptAsset
