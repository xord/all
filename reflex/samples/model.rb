# -*- coding: utf-8 -*-


%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'

include Reflex


class SliderView < View

  has_model

  def initialize ()
    add @back = View.new(name: :back, background: :white)
    add @knob = View.new(name: :knob, background: :gray, x: 50) {
      style.width 50
    }

    start = nil
    @knob.on :pointer do |e|
      case e.action
      when :down
        start = e.position
        @knob.capture :pointer
      when :up
        start = nil
        @knob.capture :none
      when :move
        self.data = (@knob.x + e.x - start.x) / knob_x_max.to_f if start
      end
    end

    super
  end

  def on_data_update (e)
    @knob.x = knob_x_max * data.to_f
    super
  end

  private

    def knob_x_max ()
      width - @knob.width
    end

end# SliderView


class LabelView < View

  has_model

  def on_draw (e)
    e.painter.text data.to_s if data
  end

end# LabelView


class ArrayView < View

  has_model

  def on_draw (e)
    e.painter.text "[#{data.to_s.chars.map{|c| "'#{c}'"}.to_a.join(', ')}]" if data
  end

end# ArrayView


win = Window.new do
  title 'Model View Sample'
  frame 100, 100, 500, 400

  add @slider = SliderView.new {set name: :slider, frame: [50, 50, 300, 30]}
  add @text   = LabelView.new  {set name: :text,   frame: [50, 150, 300, 30]}
  add @array  = ArrayView.new  {set name: :array,  frame: [50, 250, 300, 30]}

  @slider.model = @text.model = @array.model = Model.new(0) {set minmax: 0..1}
end


Reflex.start do
  win.show
end
