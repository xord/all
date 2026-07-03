require_relative 'helper'


class TestAppInterface < Test::Unit::TestCase

  include HasContext

  def interface(&block)
    R8::AppInterface.new(nil, nil).tap do |interface|
      interface.layout_popup(&block) if block
    end
  end

  def button(label = 1)
    R8::Button.new label: label
  end

  def test_popup_shows_given_widgets_and_hides_the_rest()
    a, b = button(1), button(2)
    i    = interface {[a, b].each {put _1, w: 10, h: 10}}

    i.popup a
    assert_false a.sprite.hidden?
    assert_true  b.sprite.hidden?
  end

  def test_close_popup_hides_widgets()
    a = button
    i = interface {put a, w: 10, h: 10}

    i.popup a
    i.close_popup
    assert_true a.sprite.hidden?
  end

  def test_reopening_popup_shows_widgets_again()
    a = button
    i = interface {put a, w: 10, h: 10}

    i.popup a
    i.close_popup
    i.popup a
    assert_false a.sprite.hidden?, 'popup must be visible on second open'
  end

  def test_close_popup_is_idempotent()
    a = button
    i = interface {put a, w: 10, h: 10}

    i.popup a
    i.close_popup
    i.close_popup
    i.popup a
    assert_false a.sprite.hidden?
  end

end# TestAppInterface
