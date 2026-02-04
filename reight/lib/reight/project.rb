class Reight::Project

  C = Reight::CONTEXT__

  include Xot::Inspectable

  def initialize(project_dir)
    raise 'the project directory is required' unless project_dir
    @project_dir = project_dir
    settings     = Reight::Settings.new self

    if File.exist? settings.project_json_path
      project   = read_json settings.project_json_path
      sprites   = read_json settings.sprites_json_path
      #maps      = read_json settings.maps_json_path
      #sounds    = read_json settings.sounds_json_path
      @next_id, = project.fetch :next_id
      @settings = Reight::Settings .load project.fetch(:settings), self
      @sprites  = Reight::AssetList.load Reight::SpriteAsset, sprites, self
      #@maps     = Reight::AssetList.load Reight::MapAsset,    maps,    self
      #@sounds   = Reight::AssetList.load Reight::SoundAsset,  sound,   self
    else
      @next_id  = 1
      @settings = settings
      @sprites  = Reight::AssetList.new Reight::SpriteAsset
      #@maps     = Reight::AssetList.new Reight::MapAsset
      #@sounds   = Reight::AssetList.new Reight::SoundAsset
    end
  end

  def save()
    s = settings

    File.write s.project_json_path, to_json({
      next_id:  @next_id,
      settings: s.save(self)
    }) if s.modified?

    File.write s.sprites_json_path, to_json(sprites.save(self)) if sprites.modified?
    #File.write s   .maps_json_path, to_json(   maps.save(self)) if maps   .modified?
    #File.write s .sounds_json_path, to_json( sounds.save(self)) if sounds .modified?
  end

  attr_reader :project_dir, :settings, :sprites#, :maps, :sounds

  def get_next_id()
    @next_id.tap {@next_id += 1}
  end

  def get_asset(id)
    @id2asset_cache     ||= {}
    @id2asset_cache[id] ||= @sprites.find {_1.id == id}
  end

  def path_for(name)
    File.expand_path name, project_dir
  end

  def scripts() = @codes  ||= settings.script_paths.map {File.read _1 rescue nil}

  def font      = @font   ||= C.create_font(nil, settings.font_size)

  def modified?()
    @settings.modified? || @sprites.modified? #|| @maps.modified? || @sounds.modified?
  end

  def create_sprite(name)
    sprites.find {_1.name == name}.create_sprite
  end

  def clear_all_sprites()
    sprites.each(&:clear_sprite)
    #maps   .each(&:clear_sprites)
  end

  private
=begin
  def load_maps()
    if File.file? maps_json_path
      json = JSON.parse File.read(maps_json_path), symbolize_names: true
      json.map {Reight::Map.load _1, chips}
    else
      [Reight::Map.new]
    end
  end

  def load_sounds()
    if File.file? sounds_json_path
      json = JSON.parse File.read(sounds_json_path), symbolize_names: true
      json.map {Reight::Sound.load _1}
    else
      [Reight::Sound.new]
    end
  end
=end
  def to_json(hash, readable: true)
    if readable
      JSON.pretty_generate hash
    else
      JSON.generate hash
    end
  end

  def read_json(path)
    JSON.parse File.read(path), symbolize_names: true
  end

end# Project
