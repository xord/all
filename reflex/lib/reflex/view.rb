# -*- coding: utf-8 -*-


require 'forwardable'
require 'xot/setter'
require 'xot/bit_flag_accessor'
require 'xot/universal_accessor'
require 'xot/block_util'
require 'reflex/ext'
require 'reflex/selector'
require 'reflex/style'
require 'reflex/model_view'
require 'reflex/helper'


module Reflex


  class View

    include Xot::Setter
    include Hookable
    include HasFrame
    include HasTags

    extend Forwardable

    def_delegators :style,
      :flow=,                    :flow,
      :foreground_fill=,         :foreground_fill,
      :foreground_stroke=,       :foreground_stroke,
      :foreground_stroke_width=, :foreground_stroke_width,
      :background_fill=,         :background_fill,
      :background_stroke=,       :background_stroke,
      :background_stroke_width=, :background_stroke_width,
      :foreground=,              :foreground,
      :background=,              :background,
      :fore_fill=,               :fore_fill,
      :fore_stroke=,             :fore_stroke,
      :fore_stroke_width=,       :fore_stroke_width,
      :back_fill=,               :back_fill,
      :back_stroke=,             :back_stroke,
      :back_stroke_width=,       :back_stroke_width,
      :fore=,                    :fore,
      :back=,                    :back,
      :fill=,                    :fill,
      :stroke=,                  :stroke,
      :stroke_width=,            :stroke_width,
      :image=,                   :image

    bit_flag_accessor :capture do
      flag :key,     CAPTURE_KEY
      flag :pointer, CAPTURE_POINTER
      flag :all,     CAPTURE_ALL
    end

    def initialize(options = nil, &block)
      super()
      set options if options
      Xot::BlockUtil.instance_eval_or_block_call self, &block if block
    end

    def timeout(seconds = 0, count: 1, &block)
      timer = start_timer seconds, count
      timer.block = block if block
      timer
    end

    def interval(seconds = 0, &block)
      timeout seconds, count: -1, &block
    end

    def delay(seconds = 0, &block)
      timeout seconds, &block
    end

    def remove_self()
      parent.remove self if parent
    end

    def find_child(*args)
      find_children(*args).first
    end

    def children()
      to_enum :each_child
    end

    def styles()
      to_enum :each_style
    end

    def style(*args, &block)
      s = get_style args.empty? ? nil : Selector.selector(*args)
      Xot::BlockUtil.instance_eval_or_block_call s, &block if block
      s
    end

    def shapes()
      to_enum :each_shape
    end

    def pivot=(arg)
      case arg
      when Point then set_pivot! arg.x, arg.y, arg.z
      when Array then set_pivot! arg[0], arg[1], arg[2] || 0
      else raise ArgumentError
      end
    end

    def capturing?(*args)
      cap = capture
      args.all? {|type| cap.include? type}
    end

    def on_contact(e)
    end

    def on_contact_begin(e)
    end

    def on_contact_end(e)
    end

    universal_accessor :shape, :name, :selector,
      :frame, :angle, :pivot, :zoom, :capture,
      :density, :friction, :restitution,
      :linear_velocity, :angular_velocity, :gravity_scale,
      :gravity, :time_scale,
      clip:          {reader: :clip?},
      cache:         {reader: :cache?},
      resize_to_fit: {reader: :resize_to_fit?},
      scroll_to_fit: {reader: :scroll_to_fit?},
      static:        {reader: :static?},
      dynamic:       {reader: :dynamic?},
      sensor:        {reader: :sensor?},
      debug:         {reader: :debug?}

    alias add    add_child
    alias remove remove_child
    alias find   find_child

    alias apply_impulse apply_linear_impulse
    alias velocity=     linear_velocity=
    alias velocity      linear_velocity

    alias meter meter2pixel

    def self.has_model()
      include ModelView
    end

    private

      def on_contact!(*args)
        call_contact!(*args)
        delay {on_contact(*args)}# delay to avoid physics world lock
      end

      def on_contact_begin!(*args)
        call_contact_begin!(*args)
        delay {on_contact_begin(*args)}
      end

      def on_contact_end!(*args)
        call_contact_end!(*args)
        delay {on_contact_end(*args)}
      end

  end# View


end# Reflex
