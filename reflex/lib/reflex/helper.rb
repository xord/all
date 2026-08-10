require 'xot/universal_accessor'
require 'reflex/ext'
require 'reflex/point'
require 'reflex/bounds'
require 'reflex/text_event'


module Reflex


  MODIFIER_SYMBOLS = {
    shift:    MOD_SHIFT,
    control:  MOD_CONTROL,
    alt:      MOD_ALT,
    win:      MOD_WIN,
    option:   MOD_OPTION,
    command:  MOD_COMMAND,
    help:     MOD_HELP,
    function: MOD_FUNCTION,
    numpad:   MOD_NUMPAD,
    caps:     MOD_CAPS,
    scroll:   MOD_SCROLL
  }.freeze

  SHORTCUT_MODIFIER_SYMBOLS = MODIFIER_SYMBOLS.slice(
    :shift,
    :control,
    :alt,
    :win,
    :option,
    :command
  ).freeze


  module HasFrame

    def move_to(*args)
      self.frame = frame.move_to(*args)
      self
    end

    def move_by(*args)
      self.frame = frame.move_by(*args)
      self
    end

    def resize_to(*args)
      self.frame = frame.resize_to(*args)
      self
    end

    def resize_by(*args)
      self.frame = frame.resize_by(*args)
      self
    end

    def inset_by(*args)
      self.frame = frame.inset_by(*args)
      self
    end

    %w[
      x y z w h d width height depth
      left top back right bottom front
      left_top right_top left_bottom right_bottom
      lt rt lb rb
      position pos size center
    ].each do |name|
      class_eval <<-END
        def #{name}()
          frame.#{name}
        end
        def #{name}=(*args)
          self.frame = frame.tap {|b| b.send :#{name}=, *args}
          #{name}
        end
      END

      universal_accessor name
    end

  end# HasFrame


  module HasTags

    def tag=(*tags)
      clear_tags
      tag(*tags.flatten)
    end

    alias tags= tag=

    def tag(*tags)
      tags.each {|tag| add_tag tag}
    end

    def untag(*tags)
      tags.each {|tag| remove_tag tag}
    end

    def tags()
      to_enum :each_tag
    end

    def clear_tags()
      untag(*tags.to_a)
    end

  end# HasTags


  # keeps the text being composed by the input method. defining the hooks
  # below is also what lets the view accept text input.
  module HasTextPreedit

    def preedit()
      @preedit ||= ''
    end

    def preedit_selection()
      @preedit_selection
    end

    def preedit?()
      !preedit.empty?
    end

    def on_text_preedit(e)
      @preedit, @preedit_selection = e.text, e.selection
      redraw
    end

    def on_text_commit(e)
      return unless preedit?

      @preedit, @preedit_selection = '', nil
      redraw
    end

    # draws the composing text underlined, with a double underline under the
    # clause being converted, in the painter's current font and fill color.
    def draw_preedit(painter, x, y, height: nil)
      return unless preedit?

      font     = painter.font
      height ||= font.height
      width    = font.width preedit
      uy       = y + height - 1

      painter.push stroke: painter.fill do |p|
        p.text preedit, x, y
        p.line x, uy, x + width, uy

        if preedit_selection
          sx = x + font.width(preedit[0...preedit_selection.begin] || '')
          sw =     font.width(preedit[preedit_selection]           || '')
          p.line sx, uy - 2, sx + sw, uy - 2
        end
      end
    end

  end# HasTextPreedit


end# Reflex
