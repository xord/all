# -*- coding: utf-8 -*-


require_relative 'helper'


class TestShader < Test::Unit::TestCase

  def shader(*a, **k)
    Rays::Shader.new(*a, **k)
  end

  def image(w = 10, h = 10, &block)
    Rays::Image.new(w, h).tap {|i| i.paint(&block) if block}
  end

  def color(*args)
    Rays::Color.new(*args)
  end

  def vshader()
    "void main() {gl_Position = vec4(0.0, 0.0, 0.0, 1.0);}"
  end

  def fshader()
    "void main() {gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);}"
  end

  def draw_shader(
    fragment_shader_source, fill: 1, options: {}, uniforms: {}, &block)

    image.tap do |img|
      img.paint do |p|
        p.shader shader(fragment_shader_source, **options.merge(uniforms))
        block.call p.shader if block
        p.fill(*fill)
        p.stroke nil
        p.rect img.bounds.move_to(0, 0)
      end
    end
  end

  def test_initialize()
    assert shader(fshader)
    assert shader(fshader, vshader)

    assert_raise(Rays::ShaderError) {shader "foo"}
    assert_raise(Rays::ShaderError) {shader "foo", vshader}
    assert_raise(Rays::ShaderError) {shader fshader, "foo"}
    assert_raise(Rays::ShaderError) {shader vshader}
    assert_raise(Rays::ShaderError) {shader fshader, fshader}
    assert_raise(ArgumentError) {shader nil}
  end

  def test_shader()
    assert_equal color(1, 0, 0, 1), draw_shader(<<~END, fill: [0, 1, 0, 1])[0, 0]
      void main() {gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);}
    END
  end

  def test_uniform_int()
    draw = -> (type, color_string, &b) {
      draw_shader(<<~END) {|shader| b.call shader}[0, 0].to_a
        uniform #{type} v;
        float f(int value, int div) {
          return float(value) / float(div);
        }
        void main() {
          gl_FragColor = vec4(#{color_string});
        }
      END
    }
    assert_equal [1, 0, 0, 1], draw['int',   'f(v,   1), 0.0,       0.0,       1.0']       {|sh| sh.uniform :v,  1}
    assert_equal [1, 0, 0, 1], draw['int',   'f(v,   1), 0.0,       0.0,       1.0']       {|sh| sh.uniform :v, [1]}
    assert_equal [1, 1, 0, 1], draw['ivec2', 'f(v.x, 1), f(v.y, 2), 0.0,       1.0']       {|sh| sh.uniform :v,  1, 2}
    assert_equal [1, 1, 0, 1], draw['ivec2', 'f(v.x, 1), f(v.y, 2), 0.0,       1.0']       {|sh| sh.uniform :v, [1, 2]}
    assert_equal [1, 1, 1, 1], draw['ivec3', 'f(v.x, 1), f(v.y, 2), f(v.z, 3), 1.0']       {|sh| sh.uniform :v,  1, 2, 3}
    assert_equal [1, 1, 1, 1], draw['ivec3', 'f(v.x, 1), f(v.y, 2), f(v.z, 3), 1.0']       {|sh| sh.uniform :v, [1, 2, 3]}
    assert_equal [1, 1, 1, 1], draw['ivec4', 'f(v.x, 1), f(v.y, 2), f(v.z, 3), f(v.w, 4)'] {|sh| sh.uniform :v,  1, 2, 3, 4}
    assert_equal [1, 1, 1, 1], draw['ivec4', 'f(v.x, 1), f(v.y, 2), f(v.z, 3), f(v.w, 4)'] {|sh| sh.uniform :v, [1, 2, 3, 4]}
  end

  def test_uniform_float()
    draw = -> (type, color_string, &b) {
      draw_shader(<<~END) {|shader| b.call shader}[0, 0].to_a
        uniform #{type} v;
        float f(float value, int div) {
          return value / float(div);
        }
        void main() {
          gl_FragColor = vec4(#{color_string});
        }
      END
    }
    assert_equal [1, 0, 0, 1], draw['float', 'f(v,   1), 0.0,       0.0,       1.0']       {|sh| sh.uniform :v,  1.0}
    assert_equal [1, 0, 0, 1], draw['float', 'f(v,   1), 0.0,       0.0,       1.0']       {|sh| sh.uniform :v, [1.0]}
    assert_equal [1, 1, 0, 1], draw['vec2',  'f(v.x, 1), f(v.y, 2), 0.0,       1.0']       {|sh| sh.uniform :v,  1.0, 2.0}
    assert_equal [1, 1, 0, 1], draw['vec2',  'f(v.x, 1), f(v.y, 2), 0.0,       1.0']       {|sh| sh.uniform :v, [1.0, 2.0]}
    assert_equal [1, 1, 1, 1], draw['vec3',  'f(v.x, 1), f(v.y, 2), f(v.z, 3), 1.0']       {|sh| sh.uniform :v,  1.0, 2.0, 3.0}
    assert_equal [1, 1, 1, 1], draw['vec3',  'f(v.x, 1), f(v.y, 2), f(v.z, 3), 1.0']       {|sh| sh.uniform :v, [1.0, 2.0, 3.0]}
    assert_equal [1, 1, 1, 1], draw['vec4',  'f(v.x, 1), f(v.y, 2), f(v.z, 3), f(v.w, 4)'] {|sh| sh.uniform :v,  1.0, 2.0, 3.0, 4.0}
    assert_equal [1, 1, 1, 1], draw['vec4',  'f(v.x, 1), f(v.y, 2), f(v.z, 3), f(v.w, 4)'] {|sh| sh.uniform :v, [1.0, 2.0, 3.0, 4.0]}
  end

  def test_uniform_texture()
    r, g, b = [[1, 0, 0], [0, 1, 0], [0, 0, 1]].map {|c| image {fill c; rect 10}}
    assert_equal color(1, 1, 1, 1), draw_shader(<<~END, uniforms: {tex0: r, tex1: g, tex2: b})[0, 0]
      uniform sampler2D tex0, tex1, tex2;
      varying vec4 v_TexCoord;
      void main() {
        gl_FragColor = vec4(
          texture2D(tex0, v_TexCoord.xy).r,
          texture2D(tex1, v_TexCoord.xy).g,
          texture2D(tex2, v_TexCoord.xy).b,
          1.0);
      }
    END
  end

  def test_uniform_error()
    ignore = -> bool {{ignore_no_uniform_location_error: bool}}

    assert_raise(Rays::ShaderError) {draw_shader 'void main() {}',                         uniforms: {val: 1.0}}
    assert_raise(Rays::ShaderError) {draw_shader 'void main() {}', options: ignore[false], uniforms: {val: 1.0}}
    assert_nothing_raised           {draw_shader 'void main() {}', options: ignore[true],  uniforms: {val: 1.0}}
  end

  def test_shader_source()
    assert_equal vshader, shader(fshader, vshader).vertex_shader_source
    assert_equal fshader, shader(fshader, vshader).fragment_shader_source

    assert_true shader(fshader).vertex_shader_source.then {|source|
      %w[
        a_Position a_TexCoord a_Color
        v_Position v_TexCoord v_Color
        u_PositionMatrix u_TexCoordMatrix
      ].all? {|name| source.include? name}
    }
  end

  def test_shader_env()
    env = {
      attribute_position:       'aP',
      attribute_texcoord:       ['aTC', 'aTC2'],
      attribute_color:          [],
      varying_position:         'vP',
      varying_texcoord:         nil,
      #varying_color:           define nothing
      uniform_position_matrix:  nil,
      #uniform_texcoord_matrix: define nothing
    }
    assert_true shader(fshader, nil, env).vertex_shader_source.then {|source|
      %w[
        aP
        aTC
        a_Color
        vP
        v_TexCoord
        v_Color
        u_PositionMatrix
        u_TexCoordMatrix
      ].all? {|name| source.include? name}
    }

    assert_raise(ArgumentError) {shader(fshader, nil, {attribute_color: ''})}
    assert_raise(ArgumentError) {shader(fshader, nil, {attribute_color: ['']})}
    assert_raise(ArgumentError) {shader(fshader, nil, {attribute_color: [nil]})}
    assert_raise(ArgumentError) {shader(fshader, nil, {attribute_color: ['C', '']})}
    assert_raise(ArgumentError) {shader(fshader, nil, {attribute_color: ['C', nil]})}

    assert_raise(ArgumentError) {shader(fshader, nil, {varying_color: ''})}
  end

end# TestShader
