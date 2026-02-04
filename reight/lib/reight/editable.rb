module Reight::Editable

  def self.load(asset_class, *args, state:, project:)
    asset_class.new(*args, load: {state:, project:})
  end

  def initialize(load: nil)
    @editable_modified = false if load
  end

  def save(proj)
    @editable_modified = false
    {}
  end

  def project()
    root = parent
    root = root.parent while root.parent
    raise unless root.is_a? Reight::Project
    root
  end

  def parent()
    @editable_parent
  end

  def set_parent(parent)
    @editable_parent = parent
  end

  def modified?()
    @editable_modified == nil || !!@editable_modified
  end

  def modified!()
    send_modified_event__ true
  end

  def modified(&block)
    (@editable_observers ||= []).push block
  end

  # @private
  protected def send_modified_event__(notify = true)
    @editable_modified = true
    @editable_observers&.each {_1.call self} if notify
    parent.send_modified_event__ false if parent&.modified? == false
  end

end# Editable
