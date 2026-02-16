class Reight::SpriteEditor::AnimImageList

  extend  Reight::Hookable
  extend  Reight::HasState
  include Reight::Widget

  C       = Reight::CONTEXT__
  PADDING = 1

  def initialize()
    self.anim = nil
  end

  state :anim do
    select anim&.at 0
  end

  attr_reader :anim

  hook :selected
  hook :add_image

  def select(image)
    return if image == @image
    @image = image
    selected! @image
  end

  def draw(sp)
    C.clip sp.x, sp.y, sp.w, sp.h

    image_frames.each do |image, x, y, w, h|
      if image
        C.blend image, 0, 0, image.w, image.h, x, y, w, h, REPLACE
      else
        inside = mouse_hovered? &&
          (x..(x + w)).include?(sp.mouse_x) &&
          (y..(y + h)).include?(sp.mouse_y)
        C.fill inside ? 220 : 190
        C.no_stroke
        C.rect x, y, w, h, 2
        if inside
          C.text_align CENTER, CENTER
          C.text_size 20
          C.fill 190
          C.text "+", x, y - 3, w, h
        end
      end
      if image && image == @image
        C.no_fill
        C.stroke 255
        C.rect x, y, w + 1, h + 1
      end
    end
  end

  def mouse_clicked(x, y, button)
    index, image, = image_frames
      .map.with_index {|a, i| [i, *a]}
      .find {|i, _, xx, yy, w, h| (xx..(xx + w)).include?(x) && (yy..(yy + h)).include?(y)}
    if image
      selected! image
    elsif index
      add_image! index
    end
  end

  private

  def image_frames()
    return [] unless @anim
    w = h = sprite.h - PADDING * 2
    images  = @anim.to_a
    least   = (sprite.w / sprite.h.to_f).ceil
    images += [nil] * (least - @anim.size) if least > @anim.size
    images.map.with_index do |image, index|
      [image, PADDING + (w + PADDING) * index, PADDING, w, h]
    end
  end

end# AnimImageList
