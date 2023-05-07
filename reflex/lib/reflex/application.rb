# -*- coding: utf-8 -*-


require 'xot/setter'
require 'xot/universal_accessor'
require 'xot/block_util'
require 'xot/inspectable'
require 'reflex/ext'
require 'reflex/helper'


module Reflex


  class Application

    include Xot::Setter
    include Xot::Inspectable
    include Hookable

    universal_accessor :name

    def initialize(options = nil, &block)
      super()
      set options if options
      @start_block = block if block
    end

    def self.start(*args, &block)
      new(*args, &block).start
    end

    private

      def call_start_block()
        return unless @start_block
        Xot::BlockUtil.instance_eval_or_block_call self, &@start_block
        @start_block = nil
      end

  end# Application


end# Reflex
