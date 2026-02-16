module Reight::Editable

  def self.load(asset_class, *args, state:, project:)
    asset_class.new(*args, load: {state:, project:})
  end

  def initialize(load: nil)
    @editable_modified_count = 0 if load
  end

  def save(proj)
    @editable_modified_count = 0
    {}
  end

  def project()
    o = self
    o = o.parent while o.parent
    raise unless o.is_a? Reight::Project
    o
  end

  def parent()
    @editable_parent
  end

  def set_parent(parent)
    @editable_parent = parent
  end

  def add_modified_observer(key = nil, observe_all: false, &block)
    (@editable_observers ||= []).push [block, key, observe_all]
  end

  def remove_modified_observers(key)
    @editable_observers&.delete_if {_2 == key}
  end

  alias modified add_modified_observer

  def modified?()
    @editable_modified_count == nil || @editable_modified_count > 0
  end

  def modified!()
    send_modified_event__
  end

  def modified_count()
    @editable_modified_count || 1
  end

  protected

  # @private
  def send_modified_event__(origin = true)
    @editable_modified_count ||= 1
    @editable_modified_count  += 1
    @editable_observers&.each {|b, k, all| b.call self, k if all || origin}
    parent.send_modified_event__ false if parent
  end

end# Editable
