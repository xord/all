# -*- coding: utf-8 -*-
#
# A minimal web browser built on Reflex::WebView: address bar, back /
# forward / reload buttons, and the page below. Reflex has no text-input
# widget, so the address bar and buttons are small inline View classes.

%w[xot rucy rays reflex reflex-webview]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'
require 'reflex-webview'

include Reflex


# A square button showing a glyph; calls the block on click. Can be
# disabled (drawn dim, ignores clicks).
class IconButton < View

  attr_accessor :enabled

  def initialize(glyph, &on_click)
    super(&nil)   # do not let View instance_eval our click block
    @glyph    = glyph
    @on_click = on_click
    @pressing = false
    @enabled  = true
  end

  def glyph=(g)
    @glyph = g
    redraw
  end

  def on_pointer(e)
    return unless @enabled
    case e.action
    when :down
      @pressing = true
      self.capture += [:pointer]
      redraw
    when :up
      self.capture -= [:pointer]
      @on_click.call if @pressing && frame.move_to(0, 0).include?(e.position)
      @pressing = false
      redraw
    end
  end

  def on_draw(e)
    w, h = e.bounds.size.to_a
    bg   = @pressing ? [0.30, 0.30, 0.34] : [0.20, 0.20, 0.23]
    e.painter.push fill: bg, stroke: :none do |p|
      p.rect 0, 0, w, h
      p.fill @enabled ? 0.92 : 0.40
      p.text @glyph, (w - p.font.w(@glyph)) / 2, (h - p.font.h) / 2
    end
  end

end# IconButton


# An editable address bar. While editing it captures the keyboard;
# Enter calls the on_enter block, Escape cancels.
class AddressBar < View

  attr_accessor :text

  def initialize(browser)
    super()
    @browser = browser
    @text    = ''
    @editing = false
  end

  def editing?() = @editing

  def begin_edit()
    return if @editing
    @editing = true
    self.capture += [:key]
    @browser.address_editing true
    redraw
  end

  def end_edit()
    return unless @editing
    @editing = false
    self.capture -= [:key]
    @browser.address_editing false
    redraw
  end

  def on_pointer(e)
    begin_edit if e.action == :down
  end

  def on_key(e)
    return unless @editing && e.action == :down

    case e.code
    when 36   # Return
      @browser.navigate @text
      end_edit
    when 53   # Escape
      end_edit
    when 51   # Delete (Backspace)
      @text = @text[0...-1] || ''
      redraw
    else
      c = e.chars
      mods = e.modifiers
      if !mods.include?(:command) && !mods.include?(:control) &&
         c && !c.empty? && c.ord >= 0x20
        @text += c
        redraw
      end
    end
  end

  def on_draw(e)
    w, h = e.bounds.size.to_a
    bg   = @editing ? [0.16, 0.16, 0.20] : [0.12, 0.12, 0.14]
    edge = @editing ? [0.35, 0.60, 1.00] : [0.30, 0.30, 0.30]
    e.painter.push fill: bg, stroke: edge do |p|
      p.rect 0, 0, w, h
      ty = (h - p.font.h) / 2
      p.fill 0.92
      p.no_stroke
      p.text @text, 8, ty
      if @editing
        cx = 8 + p.font.w(@text) + 1
        p.stroke 0.92
        p.line cx, ty + 2, cx, ty + p.font.h - 2
      end
    end
  end

end# AddressBar


# The page view, wired to report navigation state back to the browser.
class PageView < WebView

  def initialize(browser)
    super()
    @browser = browser
  end

  def on_load_start(e)   = @browser.loading_changed true
  def on_load(e)         = @browser.loading_changed false
  def on_load_fail(e)    = @browser.loading_changed false
  def on_url_change(e)   = @browser.url_changed url
  def on_title_change(e) = @browser.title_changed title
  def on_history_change(e) = @browser.history_changed
  def on_focus(e)        = (@browser.page_focused if e.action == :focus)

end# PageView


HOME = 'https://www.example.com/'

class SimpleBrowser < Window

  TOOLBAR_H = 48
  PAD       = 8
  BTN       = 32

  def initialize()
    super title: 'Simple Browser', frame: [80, 80, 1000, 720]
    painter.font = Font.new nil, 15

    add @page   = PageView.new(self)
    add @back   = IconButton.new('←') { @page.go_back }
    add @fwd    = IconButton.new('→') { @page.go_forward }
    add @reload = IconButton.new('↻') { @loading ? @page.stop : @page.reload }
    add @bar    = AddressBar.new(self)

    @loading = false
    layout
    @bar.text = HOME
    @page.url = HOME
  end

  def on_resize(e)
    super
    layout
    redraw
  end

  def layout()
    return unless @page   # children not created yet (early on_resize)
    w, h = frame.size.to_a
    y    = (TOOLBAR_H - BTN) / 2
    @back.frame   = [PAD,            y, BTN, BTN]
    @fwd.frame    = [PAD + BTN + 4,  y, BTN, BTN]
    @reload.frame = [PAD + (BTN + 4) * 2, y, BTN, BTN]
    bx            = PAD + (BTN + 4) * 3 + 4
    @bar.frame    = [bx, y, w - bx - PAD, BTN]
    @page.frame   = [0, TOOLBAR_H, w, h - TOOLBAR_H]
  end

  def on_draw(e)
    e.painter.push fill: [0.10, 0.10, 0.12], stroke: :none do |p|
      p.rect 0, 0, frame.w, TOOLBAR_H
    end
  end

  # --- called from PageView ---

  def navigate(text)
    text = text.strip
    return if text.empty?
    text = "https://#{text}" unless text =~ %r{\A[a-z][a-z0-9+.\-]*://}i
    @page.focus
    @page.url = text
  end

  # The address bar is starting/ending editing; blur the page while it
  # captures the keyboard so typed characters do not reach the page too.
  def address_editing(on)
    @page.focus false if on
  end

  def url_changed(u)
    @bar.text = u unless @bar.editing?
    redraw
  end

  def title_changed(t)
    self.title = t.empty? ? 'Simple Browser' : t
  end

  def loading_changed(loading)
    @loading      = loading
    @reload.glyph = loading ? '✕' : '↻'
    history_changed
  end

  def history_changed()
    @back.enabled = @page.can_go_back?
    @fwd.enabled  = @page.can_go_forward?
    @back.redraw
    @fwd.redraw
  end

  def page_focused()
    @bar.end_edit
  end

end# SimpleBrowser


Reflex.start do
  SimpleBrowser.new.show
end
