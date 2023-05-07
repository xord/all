module Xot


  module BlockUtil

    def instance_eval_or_block_call(recv, *args, **kwargs, &block)
      if block.arity == 0
        recv.instance_eval(&block)
      else
        block.call recv, *args, **kwargs
      end
    end

    extend self

  end# BlockUtil


end# Xot
