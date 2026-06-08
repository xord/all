using Reight


class Reight::Sound

  def initialize(asset, sequencer, time)
    @asset, @sequencer, @time = asset, sequencer, time
  end

  def play(gain: 1.0, &block)
    return block&.call false if @asset.empty?
    stop
    @playing = sound = to_sound__
    sound.play gain: gain

    if block
      id = "__sound_playing_check_#{sound.object_id}"
      set_interval 0.1, id: id do
        next if sound.playing? == true
        block.call true
        clear_interval id
      end
    end
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

  def to_sound__()
    RubySketch::Sound.new Beeps::Sound.new(@sequencer, @time)
  end

end# Sound
