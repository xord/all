class Reight::AssetList

  include Enumerable
  include Reight::Editable

  def self.load(asset_class, state, project)
    Reight::Editable.load Reight::AssetList, asset_class, state:, project:
  end

  def initialize(asset_class, assets = nil, type: :array, load: nil)
    super load: load
    @asset_class = asset_class
    if load
      state, project            = load.values_at :state, :project
      class_name, type_, assets = state.fetch_values :class, :type, :assets
      raise 'asset class name mismatch' if class_name != @asset_class.name
      raise ArgumentError unless assets
      @type   = type_.to_sym
      @assets = assets.map {|h| @asset_class.load h, project}
    else
      @type   = type.to_sym
      @assets = assets || []
    end

    raise 'Some assets belong to other lists' unless
      @assets.all? {_1.parent == nil}
    @assets.each {_1.set_parent self}
  end

  protected def state_variables() = {type: @type, assets: @assets}

  def save(proj)
    super.merge({
      class:  @asset_class.name,
      type:   @type,
      assets: @assets.map {_1.save proj}
    })
  end

  def insert(index, *assets)
    raise "'insert' can only be called on 'array' type" if @type != :array
    raise 'Some assets belong to other lists' unless
      assets.all? {_1.parent == nil}

    assets.each {_1.set_parent self}
    @assets.insert index, *assets
    modified!(:asset_inserted, assets:, index:)
  end

  def push(*assets)
    insert(-1, *assets)
  end

  alias append push

  def put(*assets)
    raise "'put' can only be called on 'grid' type" if @type != :grid
    raise 'Some assets belong to other lists' unless
      assets.all? {_1.parent == nil}
    raise 'Overlaps with other assets' if
      assets.any? {|asset| @assets.find {_1.hit?(*asset.frame)}}

    assets.each {_1.set_parent self}
    @assets.push(*assets)
    @assets.sort_by! {[_1.y, _1.x]}
    modified!(:asset_put, assets:)
  end

  def remove(asset)
    @assets.delete(asset)&.tap do |asset|
      asset.set_parent nil
      modified!(:asset_removed, asset:)
    end
  end

  def remove_at(index)
    @assets.delete_at(index)&.tap do |asset|
      asset.set_parent nil
      modified!(:asset_removed, asset:, index:)
    end
  end

  def each(&block)
    return enum_for :each unless block
    @assets.each(&block)
  end

  def at(index)
    @assets[index]
  end

  alias [] at

  def size()
    @assets.size
  end

  def empty?()
    @assets.empty?
  end

end# AssetList
