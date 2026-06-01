%w[../xot ../rucy ../rays .]
  .map  {|s| File.expand_path "../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/test'
require 'reflex'

require 'test/unit'

STDOUT.sync = true

module TestRunNameLogger
  def setup
    puts "[run] #{self.class}##{method_name}"
    super
  end
end
Test::Unit::TestCase.prepend(TestRunNameLogger)

include Xot::Test
