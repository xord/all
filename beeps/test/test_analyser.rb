require_relative 'helper'


class TestAnalyser < Test::Unit::TestCase

  B = Beeps

  def analyser(...)
    B::Analyser.new(...)
  end

  def osc(...)
    B::Oscillator.new(...)
  end

  def analysed(processor, nchannels: 1, **options)
    analyser(**options).tap do |an|
      B::Sound.new processor >> an, 0.1, nchannels: nchannels
    end
  end

  def spectrum(...)
    analysed(...).each_spectrum.to_a
  end

  def bin_frequency(bin, fft_size = 1024)
    B.sample_rate / fft_size.to_f * bin
  end

  def test_initialize()
    assert_equal 1024, analyser.fft_size
  end

  def test_fft_size()
    assert_equal 96, analyser(fft_size: 96).fft_size

    an = analyser
    assert_raise(ArgumentError) {an.fft_size = 48}  # not a multiple of 32
    assert_raise(ArgumentError) {an.fft_size = 224} # has the prime factor 7
    assert_equal 1024, an.fft_size
  end

  def test_process()
    assert_equal(
      get_samples(1000, osc(:sine)),
      get_samples(1000, osc(:sine) >> analyser))
  end

  def test_spectrum()
    s = spectrum osc(:sine, frequency: bin_frequency(8))
    assert_equal 512, s.size
    assert_equal 8,   s.index(s.max)
    assert_in_delta 1, s[8], 0.01
  end

  def test_spectrum_not_leaked()
    s = spectrum osc(:sine, frequency: bin_frequency(8.5))
    assert_true s[28] < 0.001
  end

  def test_spectrum_of_dc()
    assert_in_delta 0.5, spectrum(B::Value.new(0.5))[0], 0.01
  end

  def test_latest_signals()
    seq = B::Sequencer.new.tap do |s|
      s.add osc(:sine, frequency: bin_frequency(8)),  0,    0.05
      s.add osc(:sine, frequency: bin_frequency(40)), 0.05, 0.05
    end
    s = spectrum seq
    assert_equal 40, s.index(s.max)
  end

  def test_each_signal()
    assert_equal 1024, analysed(osc).each_signal.to_a.size
    assert_equal 256,  analysed(osc).each_signal(256).to_a.size
    assert_equal 1024, analysed(osc, nchannels: 2).each_signal.to_a.size
  end

end# TestAnalyser
