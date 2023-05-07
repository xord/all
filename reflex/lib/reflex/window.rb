# -*- coding: utf-8 -*-


require 'forwardable'
require 'xot/setter'
require 'xot/universal_accessor'
require 'xot/block_util'
require 'xot/inspectable'
require 'reflex/ext'
require 'reflex/helper'


module Reflex


  class Window

    include Xot::Setter
    include Xot::Inspectable
    include Hookable
    include HasFrame

    extend Forwardable

    def_delegators :root,
      :timeout, :delay, :interval,
      :add_child,     :add,
      :remove_child,  :remove,
      :children, :find_child, :find, :find_children,
      :style, :styles, :scroll_to, :scroll_by, :scroll,
      :meter2pixel, :meter, :wall,
      :zoom=,              :zoom,
      :clip=,              :clip,  :clip?,
      :cache=,             :cache, :cache?,
      :flow=,              :flow,
      :fill=,              :fill,
      :stroke=,            :stroke,
      :foreground=,        :foreground,
      :background=,        :background,
      :foreground_fill=,   :foreground_fill,
      :foreground_stroke=, :foreground_stroke,
      :background_fill=,   :background_fill,
      :background_stroke=, :background_stroke,
      :image=,             :image,
      :gravity=,           :gravity,
      :time_scale=,        :time_scale,
      :debug=,             :debug, :debug?

    def_delegators :wall,
      :friction=,    :friction,
      :restitution=, :restitution

    universal_accessor :title, :frame,
      resizable: {reader: :resizable?}

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
