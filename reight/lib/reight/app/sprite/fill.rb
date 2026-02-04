class Reight::SpriteEditor::Fill < Reight::SpriteEditor::Tool

  C = Reight::CONTEXT__

  def canvas_clicked(x, y, button)
    x, y           = [x, y].map(&:to_i)
    sx, sy, sw, sh = controller.selection
    return unless (sx...(sx + sw)).include?(x) && (sy...(sy + sh)).include?(y)
    controller.begin_editing
    w     = target_image.w
    count = 0
    target_image.update_pixels do |pixels|
      from = pixels[y * w + x]
      to   = C.color(*controller.color)
      rest = [[x, y]]
      until rest.empty?
        xx, yy = rest.shift
        next if pixels[yy * w + xx] == to
        pixels[yy * w + xx] = to
        count += 1
        extend_edited_bounds xx, yy

        _x, x_ = xx - 1, xx + 1
        _y, y_ = yy - 1, yy + 1
        rest << [_x, yy] if _x >= sx      && pixels[yy * w + _x] == from
        rest << [x_, yy] if x_ <  sx + sw && pixels[yy * w + x_] == from
        rest << [xx, _y] if _y >= sy      && pixels[_y * w + xx] == from
        rest << [xx, y_] if y_ <  sy + sh && pixels[y_ * w + xx] == from
      end
    end
    controller.end_editing if count > 0
  end

end# Fill
