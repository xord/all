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


def assert_equal_state(expected, actual, msg = nil)
  assert_equal     normalize__(expected), normalize__(actual), msg
end

def assert_not_equal_state(expected, actual, msg = nil)
  assert_not_equal normalize__(expected), normalize__(actual), msg
end

private def normalize__(obj)
  case obj
  when Array
    obj.map {normalize__ _1}
  when Hash
    obj.map {|k, v| [normalize__(k), normalize__(v)]}.to_h
  when Processing::Graphics
    [obj.size, obj.loadPixels]
  when -> o {o.respond_to? :state_variables, true}
    obj.__send__(:state_variables).transform_values {normalize__ _1}
  else
    obj
  end
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
