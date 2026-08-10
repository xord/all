# -*- coding: utf-8 -*-
require_relative 'helper'


class TestTextEvent < Test::Unit::TestCase

  PREEDIT, COMMIT = Reflex::TextEvent::PREEDIT, Reflex::TextEvent::COMMIT

  def event(*args)
    Reflex::TextEvent.new(*args)
  end

  def test_initialize()
    assert_equal :preedit, event(PREEDIT, 'あ', 1, 2).action
    assert_equal 'あ',     event(PREEDIT, 'あ', 1, 2).text
    assert_equal 1...3,    event(PREEDIT, 'あ', 1, 2).selection
  end

  def test_dup()
    assert_equal :preedit, event(PREEDIT, 'あ', 1, 2).dup.action
    assert_equal 'あ',     event(PREEDIT, 'あ', 1, 2).dup.text
    assert_equal 1...3,    event(PREEDIT, 'あ', 1, 2).dup.selection

    e1 = event PREEDIT, 'あ', 1, 2
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

  def test_preedit_commit()
    assert_true  event(PREEDIT, 'あ', 1, 2).preedit?
    assert_false event(PREEDIT, 'あ', 1, 2).commit?
    assert_false event(COMMIT,  'あ', 1, 2).preedit?
    assert_true  event(COMMIT,  'あ', 1, 2).commit?
  end

  def test_text()
    assert_equal '',              event(PREEDIT, '',  1, 2).text
    assert_equal '',              event(PREEDIT, nil, 1, 2).text
    assert_equal Encoding::UTF_8, event(PREEDIT, 'あいう', 1, 2).text.encoding
    assert_equal 3,               event(PREEDIT, 'あい😁', 1, 2).text.size
  end

  def test_selection()
    assert_nil                      event(PREEDIT, 'あいうえ', -1, 0).selection
    assert_equal 0...0,             event(PREEDIT, 'あいうえ',  0, 0).selection
    assert_equal 1...1,             event(PREEDIT, 'あいうえ',  1, 0).selection
    assert_equal 'いう', 'あいうえ'[event(PREEDIT, 'あいうえ',  1, 2).selection]
  end

end# TestTextEvent
