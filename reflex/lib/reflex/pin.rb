require 'xot/block_util'
require 'reflex/ext'


module Reflex


  class Pin

    def snap(*args, **options, &block)
      setup__ snap!(*args), options, block
    end

    def link(*args, **options, &block)
      setup__ link!(*args), options, block
    end

    def wheel(*args, **options, &block)
      setup__ wheel!(*args), options, block
    end

    def chase(*args, **options, &block)
      setup__ chase!(*args), options, block
    end

    alias pos position

    private

    def setup__(constraint, options, block)
      constraint.set options unless options.empty?
      Xot::BlockUtil.instance_eval_or_block_call constraint, &block if block
      constraint
    end

  end# Pin


end# Reflex
