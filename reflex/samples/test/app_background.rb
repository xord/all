# Manual check for Application#background and #background_menu.
#
# The application lives in the menu bar: no dock icon, a status item
# with a black circle, and it keeps running with no window open.
#
#   1. start and look at the dock
#        -> the application is not there, and nothing steals the focus
#   2. click the black circle at the right end of the menu bar
#        -> a menu opens with Settings, Toggle Dock and Quit
#   3. click Settings
#        -> a small window opens, once per click
#   4. close every window
#        -> the application keeps running, the status item stays
#   5. click Toggle Dock
#        -> the application appears in the dock with the standard menu
#           bar, and the status item stays
#   6. close every window, then click Toggle Dock in the status item menu
#        -> gone from the dock again, still running
#   7. click Quit
#        -> the application quits

%w[xot rays reflex]
  .map  {|s| File.expand_path "../../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'

icon = Rays::Image.new(16, 16).paint {fill :black; ellipse 2, 2, 12}

Reflex.start name: 'BackgroundApp' do
  settings = Reflex::Menu.new('Settings')
  toggle   = Reflex::Menu.new('Toggle Dock')
  quit     = Reflex::Menu.new('Quit')

  settings.on(:click) do |e|
    Reflex::Window.new(title: 'Settings', frame: [100, 100, 300, 200]).show
  end
  toggle.on(:click) do |e|
    app = Reflex::Application.instance
    app.background = !app.background?
  end
  quit.on(:click) {|e| Reflex::Application.instance.quit}

  self.background_menu = Reflex::Menu.new('BG', image: icon) do
    add settings
    add toggle
    add Reflex::Menu.new('-')
    add quit
  end
  self.background = true
end
