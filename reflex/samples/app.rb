%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


Reflex.start name: "AppName" do |app|
  Reflex::Window.new(:title => app.name, :frame => [100, 100, 500, 500]).show
end
