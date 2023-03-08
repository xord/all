# -*- coding: utf-8 -*-


require 'xot/setter'
require 'xot/universal_accessor'
require 'xot/block_util'
require 'reflex/ext'
require 'reflex/helper'


module Reflex


  class Shape

    include Xot::Setter
    include Hookable
    include HasFrame
    include HasTags

    alias view    owner
    alias sensor? sensor

    universal_accessor :name, :selector,
      :density, :friction, :restitution, :sensor,
      :category_bits, :collision_mask

    def initialize(options = nil, &block)
      super()
      set options if options
      Xot::BlockUtil.instance_eval_or_block_call self, &block if block
    end

    def on_contact(e)
    end

    def on_contact_begin(e)
    end

    def on_contact_end(e)
    end

    private

      def on_contact!(*args)
        call_contact!(*args)
        owner&.delay {on_contact(*args)}# delay to avoid physics world lock
      end

      def on_contact_begin!(*args)
        call_contact_begin!(*args)
        owner&.delay {on_contact_begin(*args)}
      end

      def on_contact_end!(*args)
        call_contact_end!(*args)
        owner&.delay {on_contact_end(*args)}
      end

  end# Shape


end# Reflex
