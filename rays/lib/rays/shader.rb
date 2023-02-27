# -*- coding: utf-8 -*-


require 'xot/block_util'
require 'rays/ext'


module Rays


  class Shader

    def initialize(
      fragment_shader_source,
      vertex_shader_source   = nil,
      builtin_variable_names = nil,
      ignore_no_uniform_location_error: false,
      **uniforms, &block)

      setup(
        fragment_shader_source, vertex_shader_source,
        builtin_variable_names&.values_at(
          :attribute_position, :attribute_texcoord, :attribute_color,
            :varying_position,   :varying_texcoord,   :varying_color,
          :uniform_position_matrix, :uniform_texcoord_matrix,
          :uniform_texcoord_min, :uniform_texcoord_max, :uniform_texcoord_offset,
          :uniform_texture),
        ignore_no_uniform_location_error)

      uniform(**uniforms) unless uniforms.empty?

      Xot::BlockUtil.instance_eval_or_block_call self, &block if block
    end

    def uniform(name = nil, *args, **uniforms)
      set_uniform name, *args if name
      uniforms.each do |key, value|
        set_uniform key, value
      end
    end

  end# Shader


end# Rays
