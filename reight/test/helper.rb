%w[../xot ../rucy ../beeps ../rays ../reflex ../processing ../rubysketch .]
  .map  {|s| File.expand_path "../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/test'
require 'rubysketch/all'
require 'reight/all'

require 'test/unit'
require 'tmpdir'

include Xot::Test


R8 = Reight
RS = RubySketch

class R8::Asset
  include Comparable
  def <=>(o) = state_variables <=> o&.state_variables
end

class R8::AssetList
  include Comparable
  def <=>(o) = state_variables <=> o&.state_variables
end

class R8::SpriteAsset
  include Comparable
  def <=>(o) = state_variables <=> o&.state_variables
end

class R8::SpriteAnimation
  include Comparable
  def <=>(o)
    a, b = [state_variables, o.state_variables]
      .map(&:dup)
      .each {_1[:images] = _1[:images].map(&:loadPixels)}
    a <=> b
  end
end

class R8::Map
  include Comparable
  def <=>(o) = state_variables <=> o&.state_variables
end

class R8::MapChunk
  include Comparable
  def <=>(o) = state_variables <=> o&.state_variables
end

class R8::MapTile
  include Comparable
  def <=>(o) = state_variables <=> o&.state_variables
end

class R8::Sound
  include Comparable
  alias <=> cmp__
end

class R8::Sound::Note
  include Comparable
  alias <=> cmp__
end


def tmpdir(&block) = Dir.mktmpdir(&block)
