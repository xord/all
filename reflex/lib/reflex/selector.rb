# -*- coding: utf-8 -*-


require 'xot/setter'
require 'xot/block_util'
require 'reflex/ext'
require 'reflex/helper'


module Reflex


  class Selector

    include Xot::Setter
    include HasTags

    def self.selector(*args)
      arg0 = args.first
      arg0.kind_of?(Selector) ? arg0 : self.new(*args)
    end

    def initialize(options = nil, &block)
      super()
      set options if options
      Xot::BlockUtil.instance_eval_or_block_call self, &block if block
    end

    def to_s()
      "{name:#{name}, tags:[#{tags.to_a.join ', '}]}"
    end

    def inspect()
      "#<#{self.class} #{to_s}>"
    end

  end# Selector


end# Reflex
