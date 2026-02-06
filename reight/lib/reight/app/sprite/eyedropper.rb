class Reight::SpriteEditor::Eyedropper < Reight::SpriteEditor::Tool

  C = Reight::CONTEXT__

  def canvas_clicked(x, y, button)
    editor.color = pixel_at__ image, x, y
  end

  private

  def pixel_at__(image, x, y)
    c = C.create_graphics(w, h).then do |g|
      g.begin_draw {g.blend image, x, y, w, h, 0, 0, 1, 1, REPLACE}
      g.load_pixels[0]
    end
    [C.red(c), C.green(c), C.blue(c), C.alpha(c)].map(&:to_i)
  end

end# Eyedropper
