# -*- coding: utf-8 -*-


require 'forwardable'
require 'reflex/ext'


module Reflex


  class TimerEvent < Event

    extend Forwardable

    def_delegators :timer,
      :name=, :name,
      :add_tag, :remove_tag, :each_tag,
      :selector=, :selector,
      :count=

    alias view owner

    def inspect()
      "#<Reflex::TimerEvent owner:#{owner} id:#{id} interval:#{interval} count:#{count}>"
    end

  end# TimerEvent


end# Reflex
