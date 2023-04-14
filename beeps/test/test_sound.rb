# -*- coding: utf-8 -*-


require_relative 'helper'


class TestSound < Test::Unit::TestCase

  B = Beeps

  PATH = 'test.wav'

  def sound(seconds = 0.1, processor: B::Oscillator.new, **kwargs)
    B::Sound.new processor, seconds, **kwargs
  end

  def teardown()
    File.delete PATH if File.exist?(PATH)
  end

  def test_play()
    assert_nothing_raised {sound.play}
  end

  def test_save()
    assert_false          File.exist?(PATH)
    assert_nothing_raised {sound.save PATH}
    assert_true           File.exist?(PATH)
    assert_nothing_raised {B::Sound.load PATH}
  end

  def test_sample_rate()
    assert_in_epsilon 44100, sound                    .sample_rate
    assert_in_epsilon 48000, sound(sample_rate: 48000).sample_rate
    assert_in_epsilon 96000, sound(sample_rate: 96000).sample_rate
  end

  def test_load()
    assert_nothing_raised {
      sound(0.1, nchannels: 2, sample_rate: 96000).save PATH
    }

    s = B::Sound.load PATH
    assert_in_epsilon 96000, s.sample_rate
    assert_equal      2,     s.nchannels
    assert_in_epsilon 0.1,   s.seconds
    assert_nothing_raised {s.play}
  end

end# TestBeeps
