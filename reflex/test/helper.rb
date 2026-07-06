%w[../xot ../rucy ../rays .]
  .map  {|s| File.expand_path "../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/test'
require 'reflex'

require 'test/unit'

include Xot::Test


def assert_equal_point(expected, actual, delta = 0.01, *args)
  assert_in_delta expected.x, actual.x, delta, *args
  assert_in_delta expected.y, actual.y, delta, *args
  assert_in_delta expected.z, actual.z, delta, *args
end
