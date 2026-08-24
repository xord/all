# Manual check for always_on_top and always_on_bottom.
#
# Three windows sit on top of each other, one kept above every other
# application, one kept below, and one that behaves like any other window.
# The colour and the text say which is which.
#
#   1. click another application, a browser or a finder window
#        -> the red one stays in front of it, the green one goes behind it,
#           and the blue one behaves as usual
#   2. press 2 on the blue window
#        -> it turns red and comes to the front, and stays there
#   3. press 3 on it
#        -> it turns green and drops behind the other application
#   4. press 1 on it
#        -> it is a plain window again
#   5. press 2 on the green window
#        -> it turns red. the two ends are never both on
#   6. windows only: click the green one where another application covers it
#        -> it must not come to the front

%w[xot rays reflex]
  .map  {|s| File.expand_path "../../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


COLORS = {
  normal: [0.2, 0.3, 0.6],
  top:    [0.7, 0.2, 0.2],
  bottom: [0.2, 0.5, 0.3]
}

def level_of(win)
  case
  when win.always_on_top?    then :top
  when win.always_on_bottom? then :bottom
  else                            :normal
  end
end

def set_level(win, level)
  win.always_on_top    = level == :top
  win.always_on_bottom = level == :bottom
  puts "#{win.title}: #{level_of win}"
end

%i[normal top bottom].each_with_index do |level, i|
  win = Reflex::Window.new(
    title: level.to_s,
    frame: [100 + i * 50, 100 + i * 50, 320, 140])

  set_level win, level

  win.on(:draw) do |e|
    p = e.painter
    p.background(*COLORS[level_of(win)])
    p.fill 1, 1, 1
    p.text level_of(win).to_s,             10, 10
    p.text '1: normal  2: top  3: bottom', 10, 40
  end

  win.on(:key_down) do |e|
    case e.chars
    when '1' then set_level win, :normal
    when '2' then set_level win, :top
    when '3' then set_level win, :bottom
    end
    win.redraw
  end

  win.show
end


Reflex.start
