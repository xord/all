require 'reflex'


view = Reflex::View.new
def view.on_draw(e)
  e.painter.font nil, 32
  e.painter.text 'hello, world!', 20, 20
  e.painter.font nil, 14
  e.painter.text "ruby #{RUBY_VERSION} (#{RUBY_PLATFORM})", 20, 70
end

win = Reflex::Window.new
win.title = 'Hello'
win.frame = [100, 100, 400, 200]
win.add view
win.show

Reflex.start
