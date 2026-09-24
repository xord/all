%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


# How a window can look and behave: which parts of the titlebar it shows,
# whether it draws a shadow, whether the alpha you draw with lets the desktop
# show through, and whether it can be closed, minimized or resized.
#
# Hiding a part of the titlebar takes its function away too. With the
# background hidden the window can no longer be dragged or zoomed by the strip
# the titlebar sat on, since the window itself draws there and gets the mouse
# events.
#
# The two windows differ only in what they draw behind the circles, so a
# see-through background and a translucent one can be compared. On macOS the
# shadow of a see-through window is made from what was drawn, so it follows
# the circles. Windows draws it around the frame instead.
#
# A window that lets the pointer through gets no pointer events at all. It
# cannot be clicked, dragged or activated, and the click reaches whatever sits
# behind it. Drag the two windows over each other to see where a click lands,
# the counter says which one got it. Only one window at a time can do it, so
# there is always another one left to click on.
#
# Pressing 9 again keeps the pointer going through only where the window
# drew little: with pointer_through_alpha at 0.5, the see-through window takes
# a click on its circles and passes one on its empty background, and the
# translucent window passes clicks through its 0.3 background too. The
# titlebar always takes the pointer. A third press turns it off.
#
# An unlisted window is still there on screen, but it leaves the window
# overviews: Mission Control on macOS, the taskbar and alt-tab on Windows.
# Toggle it and open the overview to watch the window drop out of the list
# while staying right where it is.
#
# Not every platform can do all of this, and the ones that cannot say so.
#
#   1: titlebar buttons, 2: titlebar background, 3: both
#   4: shadow, 5: transparent
#   6: closable, 7: minimizable, 8: resizable
#   9: pointer through, 0: unlisted
#   ESC: quit
class StyledWindow < Reflex::Window

  PARTS = [:buttons, :background]

  @@message = nil

  def initialize (title, x, alpha)
    super title: title, frame: [x, 100, 360, 360], transparent: true
    @alpha  = alpha
    @t      = 0.0
    @clicks = 0
    painter.font = Reflex::Font.new nil, 16
  end

  def on_draw (e)
    @t += 0.03
    p   = e.painter

    # the alpha here is what lets the desktop show through
    p.background 0, 0, 0, @alpha

    8.times do |i|
      a = @t + i * Math::PI / 4
      x = 180 + Math.cos(a) * 100
      y = 180 + Math.sin(a) * 100
      p.fill((Math.sin(@t + i) + 1) / 2, 0.6, 1)
      p.ellipse x - 20, y - 20, 40, 40
    end

    # something that stays put, to aim a click at
    p.fill 1, 0.8, 0.2
    p.ellipse 150, 150, 60, 60

    p.fill 1
    p.text "titlebar: #{titlebar.inspect}", 10, 10
    p.text "shadow: #{shadow?}, transparent: #{transparent?}, " \
           "unlisted: #{unlisted?}", 10, 30
    p.text "closable: #{closable?}, minimizable: #{minimizable?}, " \
           "resizable: #{resizable?}", 10, 50
    p.text "pointer through: #{pointer_through_state}, clicks: #{@clicks}", 10, 70
    p.text "#{e.fps.to_i} FPS", 10, 90
    p.text '1: buttons, 2: background, 3: both', 10, 110
    p.text '4: shadow, 5: transparent', 10, 130
    p.text '6: closable, 7: minimizable, 8: resizable', 10, 150
    p.text '9: pointer through, 0: unlisted, ESC: quit', 10, 170

    if @@message
      p.fill 1, 0.4, 0.4
      p.text @@message, 10, 190
    end
  end

  def on_update (e) = redraw

  def on_pointer_down (e)
    @clicks += 1
  end

  def on_key_down (e)
    case e.chars
    when '1' then change {|w| w.toggle_titlebar :buttons}
    when '2' then change {|w| w.toggle_titlebar :background}
    when '3' then change {|w| w.titlebar = w.titlebar.empty? ? PARTS : []}
    when '4' then change {|w| w.shadow      = !w.shadow?}
    when '5' then change {|w| w.transparent = !w.transparent?}
    when '6' then change {|w| w.closable    = !w.closable?}
    when '7' then change {|w| w.minimizable = !w.minimizable?}
    when '8' then change {|w| w.resizable   = !w.resizable?}
    when '9' then change {|w| w.cycle_pointer_through w.equal?(self)}
    when '0' then change {|w| w.unlisted    = !w.unlisted?}
    end
    Reflex.quit if e.key == :escape
  end

  def toggle_titlebar (part)
    parts         = titlebar
    self.titlebar = parts.include?(part) ? parts - [part] : parts + [part]
  end

  # off -> everything through -> only the pixels at alpha 0.5 or less -> off
  def cycle_pointer_through (mine)
    if !mine || (pointer_through? && pointer_through_alpha < 1)
      self.pointer_through = false
    elsif !pointer_through?
      self.pointer_through       = true
      self.pointer_through_alpha = 1
    else
      self.pointer_through_alpha = 0.5
    end
  end

  def pointer_through_state ()
    return 'false'                                if !pointer_through?
    return 'all'                                  if pointer_through_alpha >= 1
    return "alpha <= #{pointer_through_alpha}"
  end

  def change (&block)
    @@message = nil
    Reflex::Application.instance.windows.each(&block)
  rescue ArgumentError, NotImplementedError => e
    @@message = e.message
  end

end# StyledWindow


Reflex.start do
  StyledWindow.new('see-through', 100, 0.0).show
  StyledWindow.new('translucent', 500, 0.3).show
end
