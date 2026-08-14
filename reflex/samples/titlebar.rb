%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


# Each part of the titlebar can be hidden on its own, but hiding a part
# takes its function away too. With the background hidden the window can
# no longer be dragged or zoomed by the strip the titlebar sat on, since
# the window itself draws there and gets the mouse events.
class TitlebarWindow < Reflex::Window

  PARTS = [:buttons, :background]

  def initialize
    super title: 'titlebar', frame: [100, 100, 400, 300]
    painter.font = Reflex::Font.new nil, 16
  end

  def on_draw (e)
    p = e.painter
    p.background 0.15

    p.fill 1
    p.text "titlebar: #{titlebar.inspect}", 10, 10
    p.text '1: buttons, 2: background, 3: all, ESC: quit', 10, 40
  end

  def on_update (e) = redraw

  def on_key_down (e)
    case e.chars
    when '1' then toggle :buttons
    when '2' then toggle :background
    when '3' then self.titlebar = titlebar.empty? ? PARTS : []
    end
    Reflex.quit if e.code == 53
  end

  def toggle (part)
    parts         = titlebar
    self.titlebar = parts.include?(part) ? parts - [part] : parts + [part]
  end

end# TitlebarWindow


Reflex.start do
  TitlebarWindow.new.show
end
