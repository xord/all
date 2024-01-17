require 'xot/const_symbol_accessor'
require 'xot/universal_accessor'
require 'xot/block_util'
require 'rays/ext'


module Rays


  class Painter

    def push(*types, **attributes, &block)
      each_type types do |type|
        case type
        when :state  then push_state
        when :matrix then push_matrix
        else raise ArgumentError, "invalid push/pop type '#{type}'."
        end
      end

      raise ArgumentError, 'missing block with pushing attributes.' if
        !attributes.empty? && !block

      if block
        attributes.each do |key, value|
          attributes[key] = __send__ key
          __send__ key, *(value.nil? ? [nil] : value)
        end
        Xot::BlockUtil.instance_eval_or_block_call self, &block
      end
    ensure
      if block
        attributes.each do |key, value|
          __send__ key, *(value.nil? ? [nil] : value)
        end
        pop(*types)
      end
    end

    def pop(*types)
      each_type types, reverse: true do |type|
        case type
        when :state  then pop_state
        when :matrix then pop_matrix
        else raise ArgumentError, "invalid push/pop type '#{type}'."
        end
      end
    end

    def paint(*args, &block)
      begin_paint
      Xot::BlockUtil.instance_eval_or_block_call self, *args, &block
      self
    ensure
      end_paint
    end

    def line(*args, loop: false)
      if args.first.kind_of?(Polyline)
        polyline! args.first
      else
        line! args, loop
      end
    end

    def rect(*args, round: nil, lt: nil, rt: nil, lb: nil, rb: nil)
      rect! args, round, lt, rt, lb, rb
    end

    def ellipse(*args, center: nil, radius: nil, hole: nil, from: nil, to: nil)
      ellipse! args, center, radius, hole, from, to
    end

    def curve(*args, loop: false)
      curve! args, loop
    end

    def bezier(*args, loop: false)
      bezier! args, loop
    end

    def color=(fill, stroke = nil)
      self.fill   fill
      self.stroke stroke
    end

    def color()
      return fill, stroke
    end

    def shader=(shader, **uniforms)
      shader = Shader.new shader if shader.is_a?(String)
      shader.uniform(**uniforms) if shader && !uniforms.empty?
      set_shader shader
    end

    const_symbol_accessor :stroke_cap, **{
      butt:   CAP_BUTT,
      round:  CAP_ROUND,
      square: CAP_SQUARE
    }

    const_symbol_accessor :stroke_join, **{
      miter:  JOIN_MITER,
      round:  JOIN_ROUND,
      square: JOIN_SQUARE
    }

    const_symbol_accessor :blend_mode, **{
      normal:    BLEND_NORMAL,
      add:       BLEND_ADD,
      subtract:  BLEND_SUBTRACT,
      lightest:  BLEND_LIGHTEST,
      darkest:   BLEND_DARKEST,
      exclusion: BLEND_EXCLUSION,
      multiply:  BLEND_MULTIPLY,
      screen:    BLEND_SCREEN,
      replace:   BLEND_REPLACE
    }

    const_symbol_accessor :texcoord_mode, **{
      image:  TEXCOORD_IMAGE,
      normal: TEXCOORD_NORMAL
    }

    const_symbol_accessor :texcoord_wrap, **{
      clamp:  TEXCOORD_CLAMP,
      repeat: TEXCOORD_REPEAT
    }

    universal_accessor :background, :fill, :stroke, :color,
      :stroke_width, :stroke_outset, :stroke_cap, :stroke_join, :miter_limit,
      :nsegment, :blend_mode, :texture, :texcoord_mode, :texcoord_wrap,
      :shader, :clip, :font

    private

      def each_type(types, reverse: false, &block)
        types = [:state, :matrix] if types.empty? || types.include?(:all)
        types = types.reverse if reverse
        types.each(&block)
      end

  end# Painter


end# Rays
