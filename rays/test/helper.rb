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
