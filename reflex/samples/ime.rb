%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'

include Reflex


MARGIN = 20


# text input is enabled automatically because the text handlers are defined.
class InputView < View

  def initialize(*args, &block)
    @text = @preedit = ''
    @selection = nil
    super
  end

  def on_text_preedit(e)
    @preedit, @selection = e.text, e.selection
    redraw
  end

  def on_text_commit(e)
    @text += e.text
    @preedit, @selection = '', nil
    redraw
  end

  # tells the input method where to put the candidate window.
  def text_input_bounds()
    f = font
    [MARGIN + f.width(@text), MARGIN, f.width(@preedit), f.height]
  end

  def on_draw(e)
    f, p = font, e.painter
    x, y = MARGIN, MARGIN

    p.fill 1
    p.text @text, x, y
    x += f.width(@text)

    unless @preedit.empty?
      # keep the underlines just below the baseline, or the candidate window
      # (which opens at the bottom of text_input_bounds) hides them.
      uy = y + f.ascent + 2

      p.text @preedit, x, y
      underline p, x, uy, f.width(@preedit)

      if @selection
        # emphasize the clause being converted.
        sx = x + f.width(@preedit[0...@selection.begin] || '')
        underline p, sx, uy + 3, f.width(@preedit[@selection] || '')
      end
    end

    p.text "|", caret_x(f, x), y
  end

  private

    def font()
      window.painter.font
    end

    # the caret follows the clause being converted, or the end of the preedit.
    def caret_x(font, preedit_x)
      return preedit_x if @preedit.empty?

      count = @selection ? @selection.end : @preedit.size
      preedit_x + font.width(@preedit[0...count] || '')
    end

    def underline(painter, x, y, width)
      painter.push stroke: 1 do
        painter.line x, y, x + width, y
      end
    end

end# InputView


win = Window.new do
  set title: 'Reflex IME Sample', frame: [100, 100, 600, 200]
  painter.background 0.1
  painter.font = Font.new nil, 24

  add input = InputView.new(name: :input)
  input.focus
end


Reflex.start do
  win.show
end
