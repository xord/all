require 'forwardable'
require 'reflex/ext'


module Reflex


  class PointerEvent < Event

    extend Forwardable

    def_delegators :first,
      :id,
      :types, :mouse?, :touch?, :pen?,
      :mouse_left?, :left?, :mouse_right?, :right?, :mouse_middle?, :middle?,
      :action, :down?, :up?, :move?, :cancel?, :stay?,
      :position, :pos, :x, :y, :modifiers, :drag?, :click_count, :layer_index,
      :time, :prev

    def pointers()
      to_enum :each
    end

    def inspect()
      "#<Reflex::PointerEvent id:#{id} #{types} #{action} (#{x.round 2}, #{y.round 2}) mod:#{modifiers} drag:#{drag?} click:#{click_count} layer:#{layer_index} time:#{time.round 2}>"
    end

    private

    def first()
      self[0]
    end

  end# PointerEvent


end# Reflex
