require_relative 'helper'


class TestAppInterface < Test::Unit::TestCase

  include HasContext

  def interface(&block)
    R8::AppInterface.new(nil, nil).tap do |interface|
      interface.layout_popup(:test, &block) if block
    end
  end

  def button(label = 1)
    R8::Button.new label: label
  end

  def test_popup_shows_every_widget_its_block_puts()
    a, b = button(1), button(2)
    i    = interface {[a, b].each {put _1, w: 10, h: 10}}

    i.popup :test
    assert_false a.sprite.hidden?
    assert_false b.sprite.hidden?
  end

  def test_popup_leaves_other_popups_hidden()
    a, b = button(1), button(2)
    i    = R8::AppInterface.new nil, nil
    i.layout_popup(:one) {put a, w: 10, h: 10}
    i.layout_popup(:two) {put b, w: 10, h: 10}

    i.popup :one
    assert_false a.sprite.hidden?
    assert_true  b.sprite.hidden?
  end

  def test_popup_with_unknown_name_shows_nothing()
    a = button
    i = interface {put a, w: 10, h: 10}

    i.popup :unknown
    assert_true a.sprite.hidden?
  end

  def test_close_popup_hides_widgets()
    a = button
    i = interface {put a, w: 10, h: 10}

    i.popup :test
    i.close_popup
    assert_true a.sprite.hidden?
  end

  def test_reopening_popup_shows_widgets_again()
    a = button
    i = interface {put a, w: 10, h: 10}

    i.popup :test
    i.close_popup
    i.popup :test
    assert_false a.sprite.hidden?, 'popup must be visible on second open'
  end

  def test_close_popup_is_idempotent()
    a = button
    i = interface {put a, w: 10, h: 10}

    i.popup :test
    i.close_popup
    i.close_popup
    i.popup :test
    assert_false a.sprite.hidden?
  end

  def test_widget_creates_once_and_memoizes()
    i     = interface
    calls = 0
    made  = i.widget(:foo, -> {calls += 1; button})
    assert_equal made, i.widget(:foo)
    assert_equal made, i.widget(:foo, -> {calls += 1; button})
    assert_equal 1,    calls
  end

  def test_widget_calls_delegate_method_for_symbol_factory()
    i = interface
    b = button
    i.define_singleton_method(:new_foo) {b}
    assert_equal b, i.widget(:foo, :new_foo)
    assert_equal b, i.widget(:foo)
  end

  def test_widget_raises_before_creation()
    assert_raise(ArgumentError) {interface.widget :unknown}
  end

end# TestAppInterface
