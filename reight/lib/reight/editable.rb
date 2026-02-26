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
    @editable_modified == nil || !!@editable_modified
  end

  def modified!()
    send_modified_event__
  end

  module Accessor

    def editable_writer(name, filter: nil, &block)
      ivar_name = "@#{name}".to_sym
      define_method "#{name}=" do |value|
        value = instance_exec value, &filter if filter
        old   = instance_variable_get ivar_name
        if block
          instance_exec value, &block
        else
          instance_variable_set ivar_name, value
        end
        modified! if value != old
        value
      end
    end

  end# Accessor

  protected

  # @private
  def send_modified_event__(origin = true)
    @editable_modified = true
    @editable_observers&.each do |block, key, observe_all|
      block.call self, key if observe_all || origin
    end
    parent.send_modified_event__ false if parent
  end

end# Editable
