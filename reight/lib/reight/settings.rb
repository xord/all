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

  setting :asset_table_page_width do
    96
  end

  setting :asset_table_page_height do
    asset_table_page_width
  end

  setting :asset_table_width do
    asset_table_page_width * 4
  end

  setting :asset_table_height do
    asset_table_width
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
