%w[../xot ../rucy .]
  .map  {|s| File.expand_path "../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/test'
require 'xot/util'
require 'rays'

require 'test/unit'

include Xot::Test
include Xot::Util


def assert_equal_color(c1, c2, delta = 0.000001)
  assert_in_delta c1.r, c2.r, delta
  assert_in_delta c1.g, c2.g, delta
  assert_in_delta c1.b, c2.b, delta
  assert_in_delta c1.a, c2.a, delta
end
