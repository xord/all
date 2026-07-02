using Reight


class Reight::Navigator

  def initialize(app)
    @app, @visible = app, true
  end

  def flash(...) = message.flash(...)

  def visible=(visible)
    return if visible == @visible
    @visible = visible
    sprites.each {|sp| visible ? sp.show : sp.hide}
  end

  def visible? = @visible

  def sprites()
    [background, *app_buttons, *history_buttons, *edit_buttons, message]
      .map &:sprite
  end

  def key_pressed()
    index = [F1, F2, F3, F4, F5].index(key_code)
    app_buttons[index]&.click if index
  end

  def layout_block()
    nh, sp  = Reight::App::NAVIGATOR_HEIGHT, Reight::App::SPACE
    groups  = [app_buttons, history_buttons, edit_buttons].reject(&:empty?)
    bg, msg = background, message
    proc do
      stack h: nh do
        put bg
        row gap: 1 do
          groups.each.with_index do |buttons, index|
            space index == 0 ? sp : sp - 1
            buttons.each {put _1, w: nh}
          end
          space sp * 2 - 2
          put msg
          space sp - 1
        end
      end
    end
  end

  private

  def app_buttons()
    @app_buttons ||= @app.window.apps.map.with_index {|app, index|
      Reight::Button.new(name: app.label, icon: app.icon) {
        @app.window.app = app
      }
    }
  end

  def history_buttons()
    @history_buttons ||= [].tap do |buttons|
      next unless @app.has_history?
      buttons << Reight::Button.new(name: 'Undo', icon: r8.icon(3, 1, 8)) {
        @app.undo
      }.tap {|b|
        b.enabled? {@app.can_undo?}
      }
      buttons << Reight::Button.new(name: 'Redo', icon: r8.icon(4, 1, 8)) {
        @app.redo
      }.tap {|b|
        b.enabled? {@app.can_redo?}
      }
    end
  end

  def edit_buttons()
    @edit_buttons ||= [].tap do |buttons|
      next unless @app.has_copy_and_paste?
      buttons << Reight::Button.new(name: 'Cut',   icon: r8.icon(0, 1, 8)) {
        @app.cut
      }.tap {|b|
        b.enabled? {@app.can_cut?}
      }
      buttons << Reight::Button.new(name: 'Copy',  icon: r8.icon(1, 1, 8)) {
        @app.copy
      }.tap {|b|
        b.enabled? {@app.can_copy?}
      }
      buttons << Reight::Button.new(name: 'Paste', icon: r8.icon(2, 1, 8)) {
        @app.paste
      }.tap {|b|
        b.enabled? {@app.can_paste?}
      }
    end
  end

  def message()
    @message ||= Message.new
  end

  def background()
    @background ||= Background.new
  end

end# Navigator


class Reight::Navigator::Background

  include Reight::Widget

  def draw(sp)
    fill 220
    no_stroke
    rect 0, 0, sp.w, sp.h
  end

end# Background


class Reight::Navigator::Message

  include Reight::Widget

  def initialize()
    @priority = 0
  end

  attr_accessor :text

  def flash(str, priority: 1)
    return if priority < @priority
    @text, @priority = str, priority
    set_timeout 2, id: :message_flash do
      @text, @priority = '', 0
    end
  end

  def draw(sp)
    return unless @text
    fill 100
    text_align LEFT, CENTER
    Processing.context.text @text, 0, 0, sp.w, sp.h
  end

end# Message
