# -*- coding: utf-8 -*-


require 'reflex/ext'


module Reflex


  class UpdateEvent < Event

    def inspect()
      "#<Reflex::UpdateEvent dt:#{dt}>"
    end

  end# UpdateEvent


end# Reflex
