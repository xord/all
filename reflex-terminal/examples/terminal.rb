%w[xot rucy rays reflex reflex-terminal]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex-terminal'


def copy(terminal)
  text = terminal.selected_text
  Reflex::Clipboard.text = text unless text.empty?
end

def copyable?(terminal)
  terminal.selection?
end

def paste(terminal)
  text = Reflex::Clipboard.text
  return if text.to_s.empty?
  terminal.scroll_to 0 if terminal.scroll != 0
  terminal.paste text
end

def pasteable?()
  !Reflex::Clipboard.text.to_s.empty?
end

def resize_font(view, step)
  view.font_size = (view.font_size + step).clamp 6..96
end


terminal    = Reflex::Terminal.new.spawn
view        = Reflex::TerminalView.new terminal: terminal, font_size: 24
taken       = []
flash       = 0
flash_timer = nil

view.after :on_draw do |e|
  next if flash <= 0
  e.painter.fill 1, flash
  e.painter.rect e.bounds
  flash *= 0.9
  flash  = 0 if flash < 0.01
end

view.before :on_key_down do |e|
  # ctrl+c is the interrupt, so everywhere but macos takes shift as well
  prefix  = (Xot.osx? ? %i[command] : %i[control shift]).sort
  # a '+' needs shift wherever the layout puts it
  shifted = (prefix | [:shift]).sort

  # locks are states the keyboard is left in rather than keys held for
  # the stroke, so a shortcut has to match with them left out
  case [e.chars, e.code, e.modifiers(locks: false).sort]
  in ['+' | '=', _,             ^prefix | ^shifted] then resize_font view,  2
  in ['-',       _,             ^prefix | ^shifted] then resize_font view, -2
  in [_, Reflex::KEY_NUM_PLUS,  ^prefix]            then resize_font view,  2
  in [_, Reflex::KEY_NUM_MINUS, ^prefix]            then resize_font view, -2
  in [_, Reflex::KEY_C,         ^prefix]            then copy terminal
  in [_, Reflex::KEY_V,         ^prefix]            then paste terminal
  else next
  end

  # the press is taken, so its release has to be taken with it or the
  # child is told a key went up that it never saw go down. The modifier
  # can be let go first, so the key itself is what has to be remembered
  taken |= [e.code]
  :skip
end

view.before :on_key_up do |e|
  :skip if taken.delete e.code
end

# on the release, not the press: a native menu runs an event loop of its
# own and swallows the mouse up, which would leave the window believing the
# button was still down and every later drag starting where it was clicked
view.before :on_pointer_up do |e|
  next unless e.right?
  m = Reflex::Menu.new

  c = m.add Reflex::Menu.new('Copy')
  c.on(:show)  {|e| c.enable copyable?(terminal)}
  c.on(:click) {|e| copy terminal}

  p = m.add Reflex::Menu.new('Paste')
  p.on(:show)  {|e| p.enable pasteable?}
  p.on(:click) {|e| paste terminal}

  m.popup view, e.x, e.y
end

view.on :bell do |e|
  flash = 0.8

  flash_timer&.stop
  flash_timer = view.interval do
    view.redraw
    flash_timer.stop if flash <= 0
  end
end

win = Reflex::Window.new do
  title 'Terminal Example'
  frame 100, 100, 720, 450
end
win.add view
win.show

Reflex.start
