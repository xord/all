require_relative 'helper'


class TestMicIn < Test::Unit::TestCase

  B = Beeps

  def mic(&block)
    m = begin
      B::MicIn.new.tap(&:start)
    rescue B::OpenALError
      omit 'no mic'
    end
    block.call m
  ensure
    m&.stop
  end

  def get_signals(mic)
    B::Processor.get_signals mic, seconds: 0.1
  end

  def test_silence_not_captured_yet()
    mic do |m|
      signals = get_signals m
      assert_equal (B.sample_rate * 0.1).to_i, signals.nsamples
      assert_equal [0.0], signals.to_a.uniq
    end
  end

  def test_no_silence_once_stopped()
    mic do |m|
      m.stop
      assert_equal 0, get_signals(m).nsamples
    end
  end

  def test_not_started()
    assert_raise(ArgumentError) {get_signals B::MicIn.new}
  end

end# TestMicIn
