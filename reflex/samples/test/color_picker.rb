# Manual check for ColorPicker, the rest is in test_color_picker.rb.
#
#   ruby color_picker.rb
#        -> press c to open the picker. the window background follows the
#           picked color, and 'close' is printed when the picker closes
#           macos:   the block is called on every change while the panel is open
#           windows: the block is called once when the dialog is closed with ok
#      a   toggle alpha, then press c again (macos only)
#      d   open a second picker. on macos the first one prints 'close' at
#           once because the shared panel moves to the second one
#      q   quit
#   ruby color_picker.rb raise
#        -> the block raises. expect a ruby backtrace and status 1

%w[xot rays reflex]
  .map  {|s| File.expand_path "../../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


RAISE = ARGV[0] == 'raise'

at_exit {puts 'at_exit'}


Reflex.start do
  win     = Reflex::Window.new title: 'color_picker', frame: [100, 100, 480, 240]
  pickers = 2.times.map do |i|
    Reflex::ColorPicker.new(owner: win).tap do |picker|
      picker.on(:close) {|e| puts "close #{i + 1}"}
    end
  end
  color   = Reflex::Color.new 0.5, 0.5, 0.5

  pick = -> picker do
    picker.pick_color(color) do |c|
      raise 'boom in the color block' if RAISE
      color = c
      win.redraw
    end
  end

  win.on(:draw) do |e|
    p = e.painter
    p.fill color
    p.rect e.bounds
    p.fill 1
    p.text "color: #{color}   alpha: #{pickers[0].alpha?}", 20, 30
    p.text 'c: pick   d: pick with 2nd   a: toggle alpha   q: quit', 20, 60
  end

  win.on(:key_down) do |e|
    case e.chars
    when 'c' then pick.call pickers[0]
    when 'd' then pick.call pickers[1]
    when 'a' then pickers[0].alpha = !pickers[0].alpha?; win.redraw
    when 'q' then Reflex.quit
    end
  end

  win.show
end
