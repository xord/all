require 'xot/setter'
require 'xot/hookable'
require 'xot/block_util'
require 'xot/universal_accessor'
require 'xot/inspectable'
require 'reflex/ext'


module Reflex


  class ColorPicker

    include Xot::Setter
    include Xot::Hookable
    include Xot::Inspectable

    def initialize(options = nil, &block)
      super()
      set options if options
      Xot::BlockUtil.instance_eval_or_block_call self, &block if block
    end

    universal_accessor :owner, alpha: {reader: :alpha?}

    def pick_color(initial = nil, &block)
      @color_block = block ? -> e {block.call e.color, e} : nil
      pick_color! initial
      self
    end

    private

    def call_color_block(e)
      @color_block&.call e
    end

    def clear_color_block()
      @color_block = nil
    end

  end# ColorPicker


end# Reflex
