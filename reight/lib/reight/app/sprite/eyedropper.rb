using Reight


class Reight::SpriteEditor::Eyedropper < Reight::SpriteEditor::Tool

  def canvas_clicked(x, y, button)
    editor.color = pixel_at__ image, x, y
  end

  private

  def pixel_at__(image, x, y)
    c = create_graphics(w, h).then do |g|
      g.begin_draw {g.blend image, x, y, w, h, 0, 0, 1, 1, REPLACE}
      g.load_pixels[0]
    end
    [red(c), green(c), blue(c), alpha(c)].map(&:to_i)
  end

end# Eyedropper
