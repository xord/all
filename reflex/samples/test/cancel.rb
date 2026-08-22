# Manual check for Window_cancel_active_pointers and
# reject_unpaired_up_pointers.
#
#   1. right click
#        -> :cancel logged (down_id set), then the menu opens
#   2. close the menu (click away or select), keep watching the log
#        -> NO :up line for the canceled id must appear
#   3. move the mouse
#        -> the white dot follows (tracking alive)
#   4. hold LEFT, then right click while holding
#        -> :cancel logged for the left press, menu opens
#      close the menu, release left
#        -> NO :up for the left press
#      press left again
#        -> :down with a NEW id, then :up pairs with it as usual
#   5. plain left clicks behave as before (:down then :up, ids advance)

%w[xot rays reflex]
  .map  {|s| File.expand_path "../../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'

Reflex.start do
  menu = Reflex::Menu.new
  item = menu.add Reflex::Menu.new('Hello')
  item.on(:click) {puts "menu item clicked"}

  win = Reflex::Window.new frame: [100, 100, 400, 300]
  pos = nil

  win.on(:pointer) do |e|
    e.each do |p|
      next if p.move? && p.down.nil?   # skip hover moves to keep the log readable
      puts "%-7s id:%-3d down_id:%-5s buttons:%p pos:%s" % [
        p.action, p.id, p.down&.id.inspect, p.types, p.position.to_a.map {_1.round}
      ]
    end
    if e.move?
      pos = e.position
      win.redraw
    end
    menu.popup win.root, e.x, e.y if e.down? && e.right?
  end

  win.on(:draw) do |e|
    e.painter.push fill: :white do
      e.painter.ellipse pos.x - 5, pos.y - 5, 10, 10 if pos
    end
  end

  win.show
end
