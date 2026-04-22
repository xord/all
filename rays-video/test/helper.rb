%w[../xot ../rucy ../beeps ../rays .]
  .map  {|s| File.expand_path "../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/test'
require 'rays'
require 'rays-video'

require 'test/unit'
require 'tmpdir'

include Xot::Test


def tmpdir(&block) = Dir.mktmpdir(&block)
