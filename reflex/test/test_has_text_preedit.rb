# -*- coding: utf-8 -*-
require_relative 'helper'


class TestHasTextPreedit < Test::Unit::TestCase

  PREEDIT, COMMIT = Reflex::TextEvent::PREEDIT, Reflex::TextEvent::COMMIT

  def view(*args)
    Class.new(Reflex::View) {include Reflex::HasTextPreedit}.new(*args)
  end

  def event(*args)
    Reflex::TextEvent.new(*args)
  end

  def test_initial_state()
    v = view
    assert_equal '', v.preedit
    assert_nil       v.preedit_selection
    assert_false     v.preedit?
  end

  def test_preedit()
    v = view
    v.on_text_preedit event(PREEDIT, 'こんにちは', 1, 2)
    assert_equal 'こんにちは', v.preedit
    assert_equal 1...3,        v.preedit_selection
    assert_true                v.preedit?
  end

  def test_cancel()
    v = view
    v.on_text_preedit event(PREEDIT, 'こんにちは', 1, 2)
    v.on_text_preedit event(PREEDIT, '', -1, 0)
    assert_equal '', v.preedit
    assert_nil       v.preedit_selection
    assert_false     v.preedit?
  end

  def test_commit_clears_preedit()
    v = view
    v.on_text_preedit event(PREEDIT, 'こんにちは', 1, 2)
    v.on_text_commit  event(COMMIT,  '今日は',    -1, 0)
    assert_equal '', v.preedit
    assert_nil       v.preedit_selection
    assert_false     v.preedit?
  end

  def test_include_accepts_text_input()
    assert_true view.accepts_text_input?
  end

end# TestHasTextPreedit
