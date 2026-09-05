require_relative 'helper'


class TestApplication < Test::Unit::TestCase

  @@app = Reflex::Application.new

  def omit_on_macos_ci()
    omit 'the macos runner aborts in CoreAnimation on an event loop' if ci? && osx?
  end

  def start(&block)
    @@app.on(:start) {|e| block.call}
    @@app.start
  end

  def test_start_returns_on_quit()
    omit_on_macos_ci

    started = false
    start {started = true; @@app.quit}
    assert_true started
  end

  def test_start_returns_when_last_window_closed()
    omit_on_macos_ci

    quit = false
    @@app.on(:quit) {|e| quit = true}
    start {w = Reflex.window; w.on(:update) {|e| w.close}}
    assert_true quit
  end

  def test_start_raises_on_start_block()
    omit_on_macos_ci

    e = assert_raise(RuntimeError) {start {raise 'boom'}}
    assert_equal 'boom', e.message
    assert_match(/#{__FILE__}/, e.backtrace.first)
  end

  def test_start_raises_from_window_event()
    omit_on_macos_ci

    w = nil
    e = assert_raise(RuntimeError) do
      start {w = Reflex::Window.new; w.on(:update) {|e| raise 'in update'}}
    end
    assert_equal 'in update', e.message
  ensure
    w&.close
  end

  def test_start_passes_exit()
    omit_on_macos_ci

    e = assert_raise(SystemExit) {start {exit 3}}
    assert_equal 3, e.status
  end

  def test_start_passes_throw()
    omit_on_macos_ci

    assert_throw(:tag) {start {throw :tag}}
  end

  def test_start_twice()
    omit_on_macos_ci

    count = 0
    2.times {start {count += 1; @@app.quit}}
    assert_equal 2, count
  end

  def test_name()
    assert_equal '', @@app.name
    @@app.name = 'AppName'
    assert_equal 'AppName', @@app.name
  end

  def test_menu()
    m          = Reflex::Menu.new
    assert_nil      @@app.menu
    @@app.menu = m
    assert_equal m, @@app.menu
    @@app.menu = nil
    assert_nil      @@app.menu

    assert_raise(TypeError) {@@app.menu = 1}
  end

  def test_background()
    assert_false @@app.background?
    @@app.background = true
    assert_true  @@app.background?
    @@app.background = false
    assert_false @@app.background?
  end

  def test_background_menu()
    m                     = Reflex::Menu.new
    assert_nil      @@app.background_menu
    @@app.background_menu = m
    assert_equal m, @@app.background_menu
    @@app.background_menu = nil
    assert_nil      @@app.background_menu

    assert_raise(TypeError) {@@app.background_menu = 1}
  end

  def test_inspect()
    assert_match %r|#<Reflex::Application:0x\w{16}>|, @@app.inspect
  end

end# TestApplication
