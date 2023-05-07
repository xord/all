%w[../xot .]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'mkmf'
require 'xot/extconf'
require 'xot/extension'
require 'rucy/extension'


Xot::ExtConf.new Xot, Rucy do
  setup do
    headers << 'ruby.h'
  end

  create_makefile 'rucy/tester'
end
