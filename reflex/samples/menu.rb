%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/util'
require 'reflex'

icon = Rays::Image.new(8, 8).paint {fill :red; ellipse 0, 0, 8}

Reflex.start do
  app_menu = Reflex::Application.instance.menu || Reflex::Menu.new
  file     = app_menu.add Reflex::Menu.new('File'), index: 1
  hello    = file    .add Reflex::Menu.new('Hello', image: icon)

  popup_menu = Reflex::Menu.new
  cut        = popup_menu.add Reflex::Menu.new('Cut')
  copy       = popup_menu.add Reflex::Menu.new('Copy')
  paste      = popup_menu.add Reflex::Menu.new('Paste')

  hello.on(:click) {|e| p :hello}
  cut  .on(:click) {|e| p :cut}
  copy .on(:click) {|e| p :copy}
  paste.on(:click) {|e| p :paste}

  win      = Reflex::Window.new title: 'Menu Test', frame: [100, 100, 400, 300]
  win.menu = app_menu if Xot.win32?
  win.on(:pointer_down) {|e| popup_menu.popup win.root, e.x, e.y if e.right?}
  win.show
end
