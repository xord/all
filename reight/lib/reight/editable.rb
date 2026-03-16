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

  def add_modified_observer(*types, observer_id: nil, observe_all: false, &block)
    types = nil if types.empty?
    (@editable_observers ||= []).push [block, types, observer_id, observe_all]
  end

  def remove_modified_observer(observer_id)
    @editable_observers&.delete_if {_3 == observer_id}
  end

  alias modified add_modified_observer

  def modified?()
    @editable_modified == nil || !!@editable_modified
  end

  def modified!(type, **params)
    send_modified_event__ self, type, params
  end

  module Accessor

    def editable_writer(name, filter: nil, &block)
      ivar_name  = "@#{name}".to_sym
      event_name = :"#{name}_changed"
      define_method "#{name}=" do |value|
        value = instance_exec value, &filter if filter
        old   = instance_variable_get ivar_name
        if block
          instance_exec value, &block
          value = instance_variable_get ivar_name
        else
          instance_variable_set ivar_name, value
        end
        modified!(event_name, value:, old:) if value != old
      end
    end

  end# Accessor

  protected

  # @private
  def send_modified_event__(origin, type, params)
    @editable_modified = true
    @editable_observers&.each do |block, types, observer_id, observe_all|
      block.call(type:, origin:, observer_id:, **params) if
        (observe_all || origin == self) && (!types || types.include?(type))
    end
    parent.send_modified_event__(origin, type, params) if parent
  end

end# Editable
