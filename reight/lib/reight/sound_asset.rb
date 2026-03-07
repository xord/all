class Reight::SoundAsset < Reight::Asset

  include Enumerable
  include Xot::Inspectable

  BPM_MAX = 999

  C = Reight::CONTEXT__

  def self.load(state, project)
    Reight::Editable.load Reight::SoundAsset, state:, project:
  end

  def initialize(*args, name: nil, bpm: 120, load: nil)
    super(*args, name: name, load: load)
    if load
      state, project         = load.fetch_values :state, :project
      bpm, sequence, volumes = state.fetch_values :bpm, :sequence, :volumes
      self.bpm  = bpm
      @sequence = sequence.map {|notes| notes&.map {Reight::SoundNote.load _1, project}}
      @volumes  = volumes
    else
      self.bpm  = bpm
      @sequence = []
      @volumes  = []
    end

    modified {invalidate_cache__}
  end

  def save(proj)
    super.merge({
      bpm:      @bpm,
      sequence: @sequence.map {|notes| notes&.map {_1.save proj}},
      volumes:  @volumes
    })
  end

  protected def state_variables() =
    super.merge(bpm:, sequence: @sequence, volumes: @volumes)

  editable_writer :bpm do |bpm|
    raise ArgumentError, "Invalid bpm: #{bpm}"                            if bpm <= 0
    raise ArgumentError, "bpm exceeds the max value (#{BPM_MAX}): #{bpm}" if bpm > BPM_MAX
    @bpm = bpm
  end

  attr_reader :bpm

  def clear()
    @sequence = []
    modified! :sound_cleared
  end

  def add_note(time_index, note_index, tone)
    raise 'The note already exists' if note_at time_index, note_index
    Reight::SoundNote.new(note_index, tone).tap do |note|
      (@sequence[time_index] ||= []) << note
      modified! :note_added, time: time_index, note: note_index, tone: tone
    end
  end

  def remove_note(time_index, note_index)
    note = note_at time_index, note_index
    return nil unless note
    @sequence[time_index].delete(note)&.tap do
      modified! :note_removed, time: time_index, note: note_index, tone: note.tone
    end
  end

  def note_at(time_index, note_index)
    @sequence[time_index]&.find {_1.index == note_index}
  end

  def set_volume(time_index, volume)
    volume = volume.clamp 0, 1 if volume
    volume = nil if volume == 1
    old    = @volumes[time_index]
    return if volume == old
    @volumes[time_index] = volume
    @volumes = @volumes.reverse.drop_while(&:nil?).reverse if @volumes[-1].nil?
    modified!(:volume_changed, time: time_index, volume:)
    old
  end

  def volume_at(time_index)
    @volumes[time_index] || 1.0
  end

  def each_note(time_index: nil, &block)
    return enum_for :each_note, time_index: time_index unless block
    if time_index
      @sequence[time_index]&.each do |note|
        block.call note, time_index
      end
    else
      @sequence.each.with_index do |notes, time_i|
        notes&.each do |note|
          block.call note, time_i
        end
      end
    end
  end

  def each_volume(&block)
    return enum_for :each_volume unless block
    @volumes.each {block.call(_1 || 1.0)}
  end

  alias    add    add_note
  alias remove remove_note
  alias     at        note_at
  alias   each   each_note

  def empty?() = @sequence.all? {!_1 || _1.empty?}

  def image()  = icon_image_cache__

  def create_sound()
    Reight::Sound.new self, *sequencer__
  end

  def play(gain: 1.0)
    stop if playing?
    @playing = create_sound
    @playing.play(gain:) {@playing = nil}
  end

  def stop()
    @playing&.stop
    @playing = nil
  end

  def playing?()
    @playing = nil if @playing&.playing? == false
    !!@playing
  end

  private

  def sequencer__()
    seq   = Beeps::Sequencer.new
    time  = 0
    prevs = {}
    @sequence.each.with_index do |notes, time_index|
      sec       = Reight::SoundNote.seconds 16, @bpm
      vol       = volume_at time_index
      new_prevs = {}
      notes&.each do |note|
        osc       = Reight::SoundNote.oscillator note.tone, 32
        osc.freq  = note.frequency
        osc.phase = osc.freq * time
        env       = Reight::SoundNote.envelope sec
        gain      = Reight::SoundNote.gain vol
        seq.add osc >> env >> gain, time, sec

        new_prevs[note.tone] = [note.index, env, sec]
        pindex, penv, psec   = prevs[note.tone]

        if pindex && pindex == note.index
           env.attack  = 0
          penv.release = 0
          penv.note_off psec * 2# skip release phase
        end
      end
      time += sec
      prevs = new_prevs
    end
    return seq >> Reight::SoundNote.gain, time
  end

  def icon_image_cache__() = @icon_image_cache ||= C.create_graphics(w, h).tap do |g|
    colors   = Reight::SoundEditorInterface::TONE_COLORS
    notes    = take w
    next if notes.empty?
    min, max = notes.map {|note,| note.index}.then {[_1.min, _1.max]}
    if max - min < h
      min = min + (max - min) / 2 - h / 2
      max = min + h
    end
    g.begin_draw do
      g.no_stroke
      each_note do |note, time_index|
        g.fill colors[note.tone]
        g.rect time_index, C.map(note.index, min, max, h, 0), 1, 1
      end
    end
  end

  def invalidate_cache__()
    @icon_image_cache = nil
  end

end# SoundAsset
