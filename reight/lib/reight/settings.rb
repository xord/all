class Reight::Settings

  include Reight::Editable

  def self.load(state, project)
    Reight::Settings.new project, load: {state:}
  end

  def initialize(project, load: nil)
    @project  = project
    @settings = load ? load[:state].slice(*KEYS) : {}
  end

  def save(proj)
    super.merge @settings.slice(*KEYS)
  end

  def clear()
    @settings = {}
  end

  KEYS = []

  def self.setting(name, modifier = nil, &default_value)
    KEYS << name
    define_method name do
      @settings[name]&.then {|v| modifier ? instance_exec(v, &modifier) : v} ||
        instance_eval(&default_value)
    end
  end

  def project_json_path = path_for "project.json"

  setting :script_paths, proc {|value| [value].flatten.map {path_for _1}} do
    [path_for('game.rb')]
  end

  setting :sprites_json_name do
    'sprites.json'
  end

  setting :sprites_json_path do
    path_for sprites_json_name
  end

  setting :sprites_width do
    1024
  end

  setting :sprites_height do
    1024
  end

  setting :sprites_page_width do
    256
  end

  setting :sprites_page_height do
    256
  end

  def sprites_npages()
    w = sprites_width  / sprites_page_width .to_f
    h = sprites_height / sprites_page_height.to_f
    raise unless w == w.to_i && h == h.to_i
    (w * h).to_i
  end

  setting :maps_json_name do
    'maps.json'
  end

  setting :maps_json_path do
    path_for maps_json_name
  end

  setting :sounds_json_name do
    'sounds.json'
  end

  setting :sounds_json_path do
    path_for sounds_json_name
  end

  def palette_colors = Reight::App::PALETTE_COLORS.dup

  def font_size      = 8

  private

  def path_for(...) = @project.path_for(...)

end# Settings
