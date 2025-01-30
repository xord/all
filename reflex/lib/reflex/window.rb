require 'forwardable'
require 'xot/setter'
require 'xot/bit_flag_accessor'
require 'xot/universal_accessor'
require 'xot/hookable'
require 'xot/block_util'
require 'xot/inspectable'
require 'reflex/ext'
require 'reflex/helper'


module Reflex


  class Window

    include Xot::Setter
    include Xot::Hookable
    include Xot::Inspectable
    include HasFrame

    extend Forwardable

    bit_flag_accessor :orientations do
      flag :portrait,  ORIENTATION_PORTRAIT
      flag :landscape, ORIENTATION_LANDSCAPE
    end

    def_delegators :root,
      :add_child,    :add,
      :remove_child, :remove,
      :children, :find_children, :find_child, :find,
      :scroll_to, :scroll_by, :scroll,
      :style, :styles,
      :timeout, :delay, :interval,
      :meter2pixel, :meter, :wall,
      :zoom=,       :zoom,
      :clip=,       :clip,  :clip?,
      :cache=,      :cache, :cache?,
      :gravity=,    :gravity,
      :time_scale=, :time_scale,
      :debug=,      :debug, :debug?

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

    def_delegators :wall,
      :friction=,    :friction,
      :restitution=, :restitution

    universal_accessor :title, :frame,
      closable:    {reader: :closable?},
      minimizable: {reader: :minimizable?},
      resizable:   {reader: :resizable?},
      fullscreen:  {reader: :fullscreen?}

    def initialize(options = nil, &block)
      super()
      set options if options
      @show_block = block
    end

    def paint(&block)
      painter.begin(&block)
    end

    def self.show(*args, &block)
      new(*args, &block).show
    end

    private

      def call_show_block()
        return unless @show_block
        Xot::BlockUtil.instance_eval_or_block_call self, &@show_block
        @show_block = nil
      end

  end# Window


end# Reflex
