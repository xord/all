%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'


class Win < Reflex::Window
  def initialize ()
    super title: "Camera Example", frame: [100, 100, 800, 600]

    @w = 100
    @h = 200
    @resize_crop = Rays::Camera.new(@w, @h, resize: true,  crop: true)  {start}
    @crop        = Rays::Camera.new(@w, @h, resize: false, crop: true)  {start}
    @resize      = Rays::Camera.new(@w, @h, resize: true,  crop: false) {start}
    @original    = Rays::Camera.new(@w, @h, resize: false, crop: false) {start}
  end

  def on_draw (e)
    p = e.painter

    p.image @resize_crop.image, @w * 0, 0 if @resize_crop.image
    p.image @crop.image,        @w * 1, 0 if @crop.image
    p.image @resize.image,      @w * 2, 0 if @resize.image
    p.image @original.image,    0,     @h if @original.image

    p.text "#{e.fps.to_i} FPS", 10, 10

    p.fill nil
    p.stroke 1
    p.rect 0, 0, @w, @h
  end

  def on_update (e)
    redraw
  end
end

Reflex.start do
  Win.new.show
end
