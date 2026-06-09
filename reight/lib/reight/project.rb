using Reight


class Reight::Project

  include Xot::Inspectable
  include Reight::Editable

  def initialize(project_dir)
    raise 'the project directory is required' unless project_dir
    r            = Reight
    @project_dir = project_dir
    settings     = r::Settings.new self

    if File.exist? settings.project_json_path
      project   = read_json__ settings.project_json_path
      scripts   = read_json__ settings.scripts_json_path
      sprites   = read_json__ settings.sprites_json_path
      maps      = read_json__ settings   .maps_json_path
      sounds    = read_json__ settings .sounds_json_path
      @next_id, = project.fetch :next_id
      @settings = r::Settings .load project.fetch(:settings), self
      @scripts  = r::AssetList.load r::ScriptAsset, scripts,  self
      @sprites  = r::AssetList.load r::SpriteAsset, sprites,  self
      @maps     = r::AssetList.load r::   MapAsset, maps,     self
      @sounds   = r::AssetList.load r:: SoundAsset, sounds,   self
    else
      raise "'#{project_dir}' is not a directory" if File.file? project_dir
      FileUtils.mkdir_p project_dir
      @next_id  = 1
      @settings = settings
      @scripts  = r::AssetList.new r::ScriptAsset
      @sprites  = r::AssetList.new r::SpriteAsset, type: :grid
      @maps     = r::AssetList.new r::   MapAsset, type: :grid
      @sounds   = r::AssetList.new r:: SoundAsset, type: :grid
      r::ScriptEditor.new(self).disable_history {_1.add_script 'game.rb'}
      r::SpriteEditor.new(self).disable_history {_1.add_sprite 0, 0, 16, 16}
      r::   MapEditor.new(self).disable_history {_1.add_map    0, 0, 32, 32}
      r:: SoundEditor.new(self).disable_history {_1.add_sound  0, 0, 16, 16}
    end

    [@settings, @scripts, @sprites, @maps, @sounds].each {_1.set_parent self}
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

  def path_for(name)
    File.expand_path name, project_dir
  end

  private

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
