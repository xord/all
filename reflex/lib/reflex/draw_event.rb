# -*- coding: utf-8 -*-


require 'xot/block_util'
require 'reflex/ext'


module Reflex


  class DrawEvent < Event

    def paint(&block)
      Xot::BlockUtil.instance_eval_or_block_call painter, &block if block
    end

    def inspect()
      "#<Reflex::DrawEvent painter:#{painter} bounds:#{bounds} dt:#{dt} fps:#{fps}>"
    end

  end# DrawEvent


end# Reflex
