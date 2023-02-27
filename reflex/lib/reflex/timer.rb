# -*- coding: utf-8 -*-


require 'forwardable'
require 'reflex/ext'


module Reflex


  class Timer

    attr_accessor :block

    alias view owner

    def inspect()
      "#<Reflex::Timer owner:#{owner} id:#{id} interval:#{interval} count:#{count}>"
    end

    private

      def call_timer_block()
        @block.call self if @block
      end

  end# Timer


end# Reflex
