require 'reflex/view'


module Reflex


  class Button < View

    has_model

    attr_accessor :text

    def initialize(*args, &block)
      self.data = false
      super
      self.text = self.name unless self.text
    end

    def content_bounds()
      f = window.painter.font
      return f.width(@text) + 2, f.height + 2
    end

    def on_press(e)
    end

    def on_draw(e)
      e.painter.push fill: (pressing? ? :white : :none), stroke: :white do |p|
        p.rect e.bounds

        if @text
          p.fill pressing? ? :black : :white
          x = (e.bounds.w - p.font.w(@text)) / 2
          y = (e.bounds.h - p.font.h) / 2
          p.text @text, x, y
        end

        p.fill :none
        p.rect e.bounds
      end
    end

    def on_pointer(e)
      case e.action
      when :down
        self.capture += [:pointer]
        redraw
      when :up
        if pressing?
          self.capture -= [:pointer]
          if frame.move_to(0, 0).include? e.position
            self.data = true
            self.data = false
          end
          redraw
        end
      end
    end

    def on_data_update(e)
      on_press({}) if e.data
    end

    private

      def pressing?()
        capturing? :pointer
      end

  end# Button


end# Reflex
