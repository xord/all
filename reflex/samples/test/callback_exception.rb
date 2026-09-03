# Manual check for the paths into ruby that need a hand on the mouse or the
# keyboard, the rest is in test_application.rb. Reflex.start must return
# when the app quits, and a raise in a callback must come out of it as a
# ruby exception with a backtrace, never as 'libc++abi: terminating'.
#
#   ruby callback_exception.rb
#        -> quit with cmd-q, then again with the close button, then again
#           from the dock menu, then again with the q key. 'after start'
#           and 'at_exit' must be printed every time
#   ruby callback_exception.rb block
#        -> press cmd-q twice. the first one is blocked by on_quit, the
#           second one goes. the close button would close the window
#           first and leave the app running without one
#   ruby callback_exception.rb HOOK
#        -> raise in that hook, and expect a ruby backtrace and status 1
#      pointer   click the window
#      key       press a key
#      resize    resize the window
#      activate  switch to another app and back
#      menu      choose Raise from the File menu, or press cmd-r (ctrl-r on windows)
#      file      press o and choose a file in the dialog
#      quit      quit the app any way, on_quit raises

%w[xot rays reflex]
  .map  {|s| File.expand_path "../../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/util'
require 'reflex'


MODE = ARGV[0] || 'none'
MOD  = Xot.osx? ? :command : :control

NOTES = {
  'none'     => 'quit with cmd-q, the close button or the dock menu',
  'block'    => 'press cmd-q twice. the first one is blocked, the second one goes',
  'pointer'  => 'click the window',
  'key'      => 'press any key',
  'resize'   => 'resize the window',
  'activate' => 'switch to another app and back',
  'menu'     => "choose Raise from the File menu, or press #{MOD}-r",
  'file'     => 'press o and choose a file',
  'quit'     => 'quit any way, on_quit raises'
}

unless NOTES.key? MODE
  warn "unknown mode: #{MODE}"
  exit 2
end

at_exit {puts 'at_exit'}

def boom(where)
  raise "boom in #{where}"
end


quit_count = 0

Reflex.start do
  on(:quit) do |e|
    quit_count += 1
    boom 'on_quit' if MODE == 'quit'
    e.block        if MODE == 'block' && quit_count == 1
  end

  win = Reflex::Window.new title: "callback_exception: #{MODE}", frame: [100, 100, 480, 240]

  win.on(:draw) do |e|
    p = e.painter
    p.fill 1
    p.text "mode: #{MODE}", 20, 30
    p.text NOTES[MODE], 20, 60
    p.text 'q: quit   o: file dialog', 20, 100
  end

  win.on(:pointer_down) {|e| boom 'on_pointer_down' if MODE == 'pointer'}
  win.on(:resize)       {|e| boom 'on_resize'       if MODE == 'resize'}
  win.on(:activate)     {|e| boom 'on_activate'     if MODE == 'activate'}

  win.on(:key_down) do |e|
    boom 'on_key_down' if MODE == 'key'
    case e.chars
    when 'q' then Reflex.quit
    when 'o'
      dialog = Reflex::FileDialog.new owner: win
      dialog.on(:file) {|e| boom 'on_file' if MODE == 'file'}
      dialog.open_file {|path| puts "chosen: #{path}"}
    end
  end

  app_menu = Reflex::Application.instance.menu || Reflex::Menu.new
  file     = app_menu.add Reflex::Menu.new('File'), index: 1
  item     = file    .add Reflex::Menu.new('Raise', shortcut: [:r, MOD])
  item.on(:click) {|e| boom 'menu on_click' if MODE == 'menu'}

  win.show
end

puts 'after start'
