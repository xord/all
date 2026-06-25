using Reight


class Reight::Project

  include Xot::Inspectable
  include Reight::Editable

  def initialize(project_dir, defaults: true)
    raise 'the project directory is required' unless project_dir
    raise "'#{project_dir}' is not a directory" if File.file? project_dir
    FileUtils.mkdir_p File.join(project_dir, 'data')

    @project_dir = project_dir
    load_all__ defaults
  end

  def save(proj)
    super.merge next_id: @next_id, settings: settings.save(proj)
  end

  def save_all()
    s = settings
    File.write s.project_json_path, to_json__(        save self) if         modified?
    File.write s.scripts_json_path, to_json__(scripts.save self) if scripts.modified?
    File.write s.sprites_json_path, to_json__(sprites.save self) if sprites.modified?
    File.write s   .maps_json_path, to_json__(   maps.save self) if maps   .modified?
    File.write s .sounds_json_path, to_json__( sounds.save self) if sounds .modified?
  end

  attr_reader :project_dir, :settings, :scripts, :sprites, :maps, :sounds

  def font()
    @font ||= load_font(settings.font_path, size: settings.font_size, smooth: false)
  end

  def get_next_id()
    @next_id.tap {@next_id += 1}
  end

  def get_asset(id)
    raise ArgumentError unless id
    @id2asset_cache     ||= {}
    @id2asset_cache[id] ||= @sprites&.find {_1.id == id} || @maps&.find {_1.id == id}
  end

  def find_sprite(name)
    name = name.to_sym
    (@sprite_cache ||= {})[name] ||= sprites.find {_1.name == name}
  end

  def find_map(name)
    name = name.to_sym
    (@map_cache    ||= {})[name] ||= maps   .find {_1.name == name}
  end

  def find_sound(name)
    name = name.to_sym
    (@sound_cache  ||= {})[name] ||= sounds .find {_1.name == name}
  end

  def create_sprite(name) = find_sprite(name)&.create_sprite

  def    new_sprite(name) = find_sprite(name)&.   new_sprite

  def create_map(name)    = find_map(name)&.create_map

  def    new_map(name)    = find_map(name)&.   new_map

  def create_sound(name)  = find_sound(name)&.create_sound

  alias  new_sound create_sound

  def path_for(name, dir = nil)
    File.expand_path File.join(*dir, name), project_dir
  end

  def data_path_for(name)
    path_for name, 'data'
  end

  private

  def load_all__(defaults)
    load_project__

    load_assets__(
      Reight::ScriptAsset, Reight::ScriptEditor,
      :@scripts, @settings.scripts_json_path, :array, defaults
    ) {
      _1.add_script 'game.rb'
    }

    load_assets__(
      Reight::SpriteAsset, Reight::SpriteEditor,
      :@sprites, @settings.sprites_json_path, :grid, defaults
    ) {
      _1.add_sprite 0, 0, 16, 16
    }

    load_assets__(
      Reight::MapAsset, Reight::MapEditor,
      :@maps, @settings.maps_json_path, :grid, defaults
    ) {
      _1.add_map 0, 0, 32, 32
    }

    load_assets__(
      Reight::SoundAsset, Reight::SoundEditor,
      :@sounds, @settings.sounds_json_path, :grid, defaults
    ) {
      _1.add_sound 0, 0, 16, 16
    }

    [@settings, @scripts, @sprites, @maps, @sounds].each {_1.set_parent self}
  end

  def load_project__()
    settings = Reight::Settings.new self
    path     = settings.project_json_path
    if File.exist? path
      project   = read_json__ path
      @next_id, = project.fetch :next_id
      @settings = Reight::Settings.load project.fetch(:settings), self
    else
      @next_id  = 1
      @settings = settings
    end
  end

  def load_assets__(asset_class, editor_class, ivar, json_path, list_type, defaults, &block)
    if File.exist? json_path
      instance_variable_set ivar, Reight::AssetList.load(asset_class, read_json__(json_path), self)
    else
      instance_variable_set ivar, Reight::AssetList.new(asset_class, type: list_type)
      editor_class.new(self).disable_history(&block) if defaults
    end
  end

  def to_json__(hash, readable: true)
    if readable
      JSON.pretty_generate hash
    else
      JSON.generate hash
    end
  end

  def read_json__(path)
    JSON.parse File.read(path), symbolize_names: true
  rescue Errno::ENOENT
    nil
  end

end# Project
