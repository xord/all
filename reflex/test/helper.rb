%w[../xot ../rucy ../rays .]
  .map  {|s| File.expand_path "../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/test'
require 'reflex'

require 'test/unit'

STDOUT.sync = true

Test::Unit::TestCase.add_setup_hook do |t|
  puts "[run] #{t.class}##{t.method_name}"
end

include Xot::Test
