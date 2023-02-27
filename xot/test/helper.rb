# -*- coding: utf-8 -*-


%w[.]
  .map  {|s| File.expand_path "../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'test/unit'
require 'xot'
require 'xot/test'
require_relative '../ext/xot/tester'

include Xot::Test
