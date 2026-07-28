%w[xot rucy rays reflex reflex-terminal]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'
require 'reflex-terminal'


win = Reflex::Window.new {
  title 'Terminal Example'
  frame 100, 100, 720, 450
}
win.add Reflex::TerminalView.new(font_size: 24)
win.show

Reflex.start
