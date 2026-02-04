class Reight::AssetList

  include Enumerable
  include Reight::Editable

  def self.load(asset_class, state, project)
    Reight::Editable.load Reight::AssetList, asset_class, state:, project:
  end

  def initialize(asset_class, assets = nil, load: nil)
    @asset_class = asset_class
    if load
      state, project     = load.values_at :state, :project
      class_name, assets = state.values_at :class, :assets
      raise 'asset class name mismatch' if class_name != @asset_class.name
      raise ArgumentError unless assets
      @assets = assets.map {|h| @asset_class.load h, project}
    else
      @assets = assets || []
    end
  end

  protected def state_variables() = {assets: @assets}

  def save(proj)
    super.merge class: @asset_class.name, assets: @assets.map {_1.save proj}
  end

  def insert(index, *assets)
    assets.each {_1.set_parent self}
    @assets.insert index, *assets
    modified!
  end

  def push(*assets)
    insert(-1, *assets)
  end

  alias append push

  def remove(asset)
    @assets.delete(asset)&.tap do |asset|
      asset.set_parent nil
      modified!
    end
  end

  def remove_at(index)
    @assets.delete_at(index)&.tap do |asset|
      asset.set_parent nil
      modified!
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
