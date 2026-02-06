using Reight


class Reight::SpriteEditor < Reight::App

  def initialize(project)
    super project, Reight::SpriteEditor::Controller, Reight::SpriteEditor::Interface
  end

end# SpriteEditor
