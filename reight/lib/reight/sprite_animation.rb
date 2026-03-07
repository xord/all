class Reight::SpriteAnimation < Reight::Asset

  extend  Reight::Editable::Accessor
  include Enumerable
  include Xot::Inspectable

  C = Reight::CONTEXT__

  def self.load(state, project)
    Reight::Editable.load Reight::SpriteAnimation, state:, project:
  end

  def initialize(id = 0, width = 0, height = 0, fps: 2, name: nil, load: nil)
    super id, width, height, name: name, load: load
    if load
      state, project = load.fetch_values :state, :project
      @fps    = state.fetch :fps
      @images = load_images__ project
    else
      @fps, @images = fps, []
    end
    raise ArgumentError if @fps <= 0
  end

  def save(proj)
    save_images__ proj if modified?
    super.merge fps: @fps
  end

  protected def state_variables() = super.merge(fps:, images: @images)

  editable_writer :fps

  attr_reader :fps

  def insert(index, *images)
    raise 'invalid image size' unless
      images.all? {_1.width == width && _1.height == height}
    @images.insert index, *images
    modified!(:image_added, images:, index:)
  end

  def push(*images)
    insert(-1, *images)
  end

  alias append push

  def remove(image)
    @images.delete(image)&.tap do
      modified!(:image_removed, image:)
    end
  end

  def remove_at(index)
    @images.delete_at(index)&.tap do |image|
      modified!(:image_removed, image:, index:)
    end
  end

  def each(&block)
    return enum_for :each unless block
    @images.each(&block)
  end

  def at(index)
    return nil if @images.empty?
    @images[index % @images.size]
  end

  alias [] at

  def image_at(frame_count)
    return nil if @images.empty?
    self[(frame_count / (60 / fps)).to_i % size]
  end

  def size()
    @images.size
  end

  def empty?()
    @images.empty?
  end

  def asset_type()
    'anim'
  end

  def create_image()
    C.create_graphics w, h
  end

  private

  # @private
  def save_images__(project)
    path = image_path__ project
    if empty?
      File.delete path if File.exist? path
    else
      to_atlas_image__.save path
    end
  end

  # @private
  def load_images__(project)
    path = image_path__ project
    return [] unless File.exist? path
    from_atlas_image__ C.load_image path
  end

  # @private
  def image_path__(project)
    project.path_for "#{asset_type}_#{id}.png"
  end

  # @private
  def to_atlas_image__()
    C.create_graphics(w * @images.size, h).tap do |g|
      g.begin_draw do
        @images.each.with_index do |img, index|
          g.blend img, 0, 0, w, h, w * index, 0, w, h, :replace
        end
      end
    end
  end

  # @private
  def from_atlas_image__(image)
    [(image.width / w).floor, 1].max.times.map do |index|
      C.create_graphics(w, h).tap do |g|
        g.begin_draw do
          g.background 0, 0, 0, 0
          g.blend image, w * index, 0, w, h, 0, 0, w, h, :replace
        end
      end
    end
  rescue
    []
  end

end# SpriteAnimation
