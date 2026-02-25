class Reight::SoundNote

  include Reight::Editable

  MAX   = 127

  TONES = %i[
    sine triangle square sawtooth pulse12_5 pulse25 noise
  ].freeze

  def self.load(state, project)
    Reight::Editable.load Reight::SoundNote, state:, project:
  end

  def initialize(index = 0, tone = nil, load: nil)
    super load: load
    if load
      state,      = load.fetch_values :state
      index, tone = state
      raise ArgumentError unless index && tone && tone >= 0
      @index, @tone  = index.to_i, TONES[tone]
    else
      tone ||= TONES.first
      @index, @tone  = index.to_i, tone.to_sym
    end
    raise ArgumentError, "Invalid note index: #{index}" unless (0..MAX).include? @index
    raise ArgumentError, "Invalid tone: #{tone}"        unless    TONES.include? @tone
  end

  def save(proj)
    [@index, TONES.index(@tone)]
  end

  protected def state_variables() = {index:, tone:}

  attr_reader :index, :tone

  def play(bpm)
    to_sound(bpm).play
  end

  def frequency()
    440 * (2 ** ((@index - 69).to_f / 12))
  end

  INDEX2NOTE = -> {
    notes   = %w[ c c+ d d+ e f f+ g g+ a a+ b ].map {_1.sub '+', '#'}
    octaves = (-1..9).to_a
    octaves.product(notes)
      .each_with_object({}).with_index do |((octave, note), hash), index|
        hash[index] = "#{note}#{octave}"
      end
  }.call

  def to_s()
    "#{INDEX2NOTE[@index]}:#{@tone}"
  end

  def to_sound(bpm)
    osc  = self.class.oscillator tone, 32, freq: frequency
    sec  = self.class.seconds 4, bpm
    seq  = Beeps::Sequencer.new.tap {_1.add osc, 0, sec}
    env  = self.class.envelope sec
    gain = self.class.gain
    RubySketch::Sound.new Beeps::Sound.new(seq >> env >> gain, sec)
  end

  def self.oscillator(type, size, **kwargs)
    case type
    when :noise then Beeps::Oscillator.new type, **kwargs
    else
      samples = (@samples ||= {})[type] ||= create_samples type, size
      Beeps::Oscillator.new samples: samples, **kwargs
    end
  end

  def self.create_samples(type, size)
    input = size.times.map {_1.to_f / size}
    duty  = {pulse12_5: 0.125, pulse25: 0.25, pulse75: 0.75}[type] || 0.5
    case type
    when :sine     then input.map {Math.sin _1 * Math::PI * 2}
    when :triangle then input.map {_1 < 0.5 ? _1 * 4 - 1 : 3 - _1 * 4}
    when :sawtooth then input.map {_1 * 2 - 1}
    else                input.map {_1 < duty ? 1 : -1}
    end
  end

  def self.envelope(seconds)
    Beeps::Envelope.new release: seconds * 0.05 do
      note_on
      note_off seconds * 0.95
    end
  end

  def self.gain(gain = 0.2)
    Beeps::Gain.new gain
  end

  def self.seconds(length, bpm)
    raise ArgumentError, "Invalid length: #{length}" if length <= 0
    raise ArgumentError, "Invalid bpm: #{bpm}"       if bpm    <= 0
    60.0 / bpm / length
  end

end# SoundNote
