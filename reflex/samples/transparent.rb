%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


# Two windows so that the shared GL context keeps moving between them,
# which is the case where the surface opacity has to be set again.
# SPACE toggles the transparency of both windows, ESC or Q quits.
class TransparentWindow < Reflex::Window

  def initialize (title, x, alpha)
    super title: title, frame: [x, 100, 320, 320], transparent: true
    @alpha = alpha
    @t     = 0.0
    painter.font = Reflex::Font.new nil, 16
  end

  def on_draw (e)
    @t += 0.03
    p   = e.painter

    # the alpha here is what makes the desktop show through
    p.background 0, 0, 0, @alpha

    8.times do |i|
      a = @t + i * Math::PI / 4
      x = 160 + Math.cos(a) * 90
      y = 160 + Math.sin(a) * 90
      p.fill((Math.sin(@t + i) + 1) / 2, 0.6, 1)
      p.ellipse x - 20, y - 20, 40, 40
    end

    p.fill 1
    p.text "transparent: #{transparent?}", 10, 10
    p.text "#{e.fps.to_i} FPS", 10, 30
    p.text 'SPACE: toggle, ESC: quit', 10, 50
  end

  def on_update (e) = redraw

  def on_key_down (e)
    case
    when e.chars == ' '                  then toggle_all
    when e.code == 53 || e.chars =~ /q/i then Reflex.quit
    end
  end

  def toggle_all
    Reflex::Application.instance.windows.each do |w|
      w.transparent = !w.transparent?
    end
  end

end# TransparentWindow


Reflex.start do
  TransparentWindow.new('transparent 1', 100, 0.0).show
  TransparentWindow.new('transparent 2', 460, 0.3).show
end
