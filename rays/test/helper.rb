# -*- coding: utf-8 -*-


%w[../xot ../rucy .]
  .map  {|s| File.expand_path "../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'test/unit'
require 'xot/test'
require 'rays'

include Xot::Test


unless defined?($RAYS_NOAUTOINIT) && $RAYS_NOAUTOINIT
  def Rays.fin!() end
end


def assert_equal_color(c1, c2, delta = 0.000001)
  assert_in_delta c1.r, c2.r, delta
  assert_in_delta c1.g, c2.g, delta
  assert_in_delta c1.b, c2.b, delta
  assert_in_delta c1.a, c2.a, delta
end
