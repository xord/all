module Processing


  # Shader object.
  #
  class Shader

    # Initialize shader object.
    #
    # @param vertSrc [String] vertex shader source
    # @param fragSrc [String] fragment shader source
    #
    def initialize(vertSrc, fragSrc)
      @shader = Rays::Shader.new fragSrc, vertSrc, ENV__
    end

    # Sets uniform variables.
    #
    # @overload set(name, a)
    # @overload set(name, a, b)
    # @overload set(name, a, b, c)
    # @overload set(name, a, b, c, d)
    # @overload set(name, nums)
    # @overload set(name, vec)
    # @overload set(name, vec, ncoords)
    # @overload set(name, tex)
    #
    # @param name    [String]  uniform variable name
    # @param a       [Numeric] int or float value
    # @param b       [Numeric] int or float value
    # @param c       [Numeric] int or float value
    # @param d       [Numeric] int or float value
    # @param nums    [Array]   int or float array
    # @param vec     [Vector]  vector
    # @param ncoords [Integer] number of coordinates, max 4
    # @param tex     [Image]   texture image
    #
    def setUniform(name, *args)
      arg = args.first
      case
      when Array === arg
        @shader.uniform name, *arg
      when Numeric === arg
        @shader.uniform name, *args
      when Vector === arg
        vec, ncoords = args
        @shader.uniform name, vec.getInternal__.to_a(ncoords || 3)
      when arg.respond_to?(:getInternal__)
        @shader.uniform name, arg.getInternal__
      else
        raise ArgumentError
      end
    end

    alias set setUniform

    # @private
    def getInternal__()
      @shader
    end

    # @private
    ENV__ = {
      attribute_position:      [:vertex, :position],
      attribute_texcoord:      :texCoord,
      attribute_color:         :color,
      varying_position:        :vertPosition,
      varying_texcoord:        :vertTexCoord,
      varying_color:           :vertColor,
      uniform_position_matrix: [:transform, :transformMatrix],
      uniform_texcoord_matrix: :texMatrix,
      uniform_texcoord_min:    :texMin,
      uniform_texcoord_max:    :texMax,
      uniform_texcoord_offset: :texOffset,
      uniform_texture:         [:texMap, :texture]
    }.freeze

    # @private
    def self.createFilter__(*args)
      case arg = args.shift
      when Shader
        arg
      when :threshold
        self.new(nil, <<~END).tap {|sh| sh.set :threshold, (args.shift || 0.5)}
          uniform float threshold;
          uniform sampler2D texMap;
          varying vec4 vertTexCoord;
          varying vec4 vertColor;
          void main() {
            vec4 col     = texture2D(texMap, vertTexCoord.xy) * vertColor;
            float gray   = col.r * 0.3 + col.g * 0.59 + col.b * 0.11;
            gl_FragColor = vec4(vec3(gray > threshold ? 1.0 : 0.0), 1.0);
          }
        END
      when :gray
        self.new nil, <<~END
          uniform sampler2D texMap;
          varying vec4 vertTexCoord;
          varying vec4 vertColor;
          void main() {
            vec4 col     = texture2D(texMap, vertTexCoord.xy);
            float gray   = col.r * 0.3 + col.g * 0.59 + col.b * 0.11;
            gl_FragColor = vec4(vec3(gray), 1.0) * vertColor;
          }
        END
      when :invert
        self.new nil, <<~END
          uniform sampler2D texMap;
          varying vec4 vertTexCoord;
          varying vec4 vertColor;
          void main() {
            vec4 col     = texture2D(texMap, vertTexCoord.xy);
            gl_FragColor = vec4(vec3(1.0 - col.rgb), 1.0) * vertColor;
          }
        END
      when :blur
        self.new(nil, <<~END).tap {|sh| sh.set :radius, (args.shift || 1).to_f}
          #define PI 3.1415926538
          uniform float radius;
          uniform sampler2D texMap;
          uniform vec3 texMin;
          uniform vec3 texMax;
          uniform vec3 texOffset;
          varying vec4 vertTexCoord;
          varying vec4 vertColor;
          float gaussian(vec2 pos, float sigma) {
            float s2 = sigma * sigma;
            return 1.0 / (2.0 * PI * s2) * exp(-(dot(pos, pos) / (2.0 * s2)));
          }
          void main() {
            float sigma        = radius * 0.5;
            vec3 color         = vec3(0.0);
            float total_weight = 0.0;
            for (float y = -radius; y < radius; y += 1.0)
            for (float x = -radius; x < radius; x += 1.0) {
              vec2 offset   = vec2(x, y);
              float weight  = gaussian(offset, sigma);
              vec2 texcoord = vertTexCoord.xy + offset * texOffset.xy;
              if (
                texcoord.x < texMin.x || texMax.x < texcoord.x ||
                texcoord.y < texMin.y || texMax.y < texcoord.y
              ) continue;
              color += texture2D(texMap, texcoord).rgb * weight;
              total_weight += weight;
            }
            gl_FragColor = vec4(color / total_weight, 1.0) * vertColor;
          }
        END
      else
        nil
      end
    end

  end# Shader


end# Processing
