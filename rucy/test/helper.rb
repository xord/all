# -*- coding: utf-8 -*-


%w[../xot .]
  .map  {|s| File.expand_path "../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/test'
require 'rucy'
require_relative '../ext/rucy/tester'

require 'test/unit'

include Xot::Test
