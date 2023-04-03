# -*- coding: utf-8 -*-


require 'beeps/ext'


module Beeps


  class Sound

    def initialize(processor, seconds = nil, nchannels: nil, sample_rate: nil)
      setup processor, seconds, nchannels, sample_rate
    end

    def self.load(path)
      f = FileIn.new path
      Sound.new f, f.seconds, f.nchannels
    end

  end# Sound


end# Beeps
