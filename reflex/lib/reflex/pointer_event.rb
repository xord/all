require 'forwardable'
require 'reflex/ext'


module Reflex


  class PointerEvent < Event

    include Enumerable

    extend Forwardable

    def_delegators :first,
      :id,
      :types, :mouse?, :touch?, :pen?,
      :mouse_left?, :left?, :mouse_right?, :right?, :mouse_middle?, :middle?,
      :action, :down?, :up?, :move?, :cancel?, :enter?, :leave?, :stay?,
      :position, :pos, :x, :y, :modifiers, :click_count, :drag?,
      :time, :prev, :down

    def pointers()
      to_enum :each
    end

    def inspect()
      "#<Reflex::PointerEvent id:%d %p %p (%p, %p) mod:%p click:%d drag:%p time:%p>" %
      [
        id,
        types,
        action,
        x.round(2),
        y.round(2),
        modifiers(all: true),
        click_count,
        drag?,
        time.round(2)
      ]
    end

  end# PointerEvent


end# Reflex
