# Manual check for the synthesized window enter/leave.
#
# The window's edge is drawn as a frame: green while the pointer is inside,
# red while it is outside, so what the log says can be seen at a glance.
#
#   1. move the mouse in and out with NO button held
#        -> one :enter on the way in, one :leave on the way out, never a pair
#   2. press LEFT inside, drag out, drag back in, release inside
#        -> :leave on the way out, :enter on the way back in, both WHILE
#           dragging. this is what no platform used to send
#   3. release the button outside, then move back in
#        -> a single :enter, not one for the release and one for the move
#   4. cross the edge quickly, several times
#        -> the count of :enter and :leave stays balanced, never two in a row
#   5. macos only: after step 2, watch for a late :enter once the button is
#      released
#        -> there must NOT be one; it was already announced during the drag
#   6. right click inside to pop a menu up, dismiss it, then move in and out
#        -> :cancel is logged, and the boundary keeps working afterwards. the
#           frame may turn red while the menu covers the window
#   7. hold LEFT, drag outside, then right click to pop the menu up
#        -> :cancel is logged for the left press; moving back in still gives a
#           single :enter, and releasing left produces nothing

%w[xot rays reflex]
  .map  {|s| File.expand_path "../../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'

Reflex.start do
  menu = Reflex::Menu.new
  item = menu.add Reflex::Menu.new('Hello')
  item.on(:click) {puts 'menu item clicked'}

  win     = Reflex::Window.new frame: [100, 100, 400, 300]
  inside  = false
  last    = nil
  pressed = false

  show = -> action, e do
    puts "%-6s pressed:%-5s pos:%s" % [
      action, pressed, e.position.to_a.map {_1.round}
    ]
  end

  boundary = -> action, e do
    warn "TWO #{action} IN A ROW" if action == last
    last = action
    show[action, e]
  end

  win.on(:pointer_enter) {|e| inside = true;  boundary[:enter, e]; win.redraw}
  win.on(:pointer_leave) {|e| inside = false; boundary[:leave, e]; win.redraw}

  win.on(:pointer_down) do |e|
    pressed = true
    menu.popup win.root, e.x, e.y if e.right?
  end

  win.on(:pointer_up) {|e| pressed = false}

  win.on(:pointer_cancel) do |e|
    pressed = false
    show[:cancel, e]
  end

  win.on(:draw) do |e|
    e.painter.push fill: nil, stroke: (inside ? :green : :red), stroke_width: 8 do
      e.painter.rect 4, 4, e.bounds.width - 8, e.bounds.height - 8
    end
  end

  win.show
end
