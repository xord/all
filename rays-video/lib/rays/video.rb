require 'xot/block_util'
require 'beeps/ext'
require 'rays/ext'
require 'rays-video/ext'


module Rays


  class Video

    include Enumerable

    def initialize(width, height, fps: 0, pixel_density: 1, &block)
      initialize! width, height, fps, pixel_density
      Xot::BlockUtil.instance_eval_or_block_call self, &block if block
    end

    def insert(index, *images)
      images.each.with_index {|image, i| insert! index + i, image}
    end

    def append(*images)
      images.each {|image| append! image}
    end

    def remove(index_or_range)
      case index_or_range
      when Range then raise NotImplementedError
      else remove! index_or_range
      end
    end

    alias pos= position=
    alias pos  position

    def each(&block)
      return enum_for :each unless block
      each!(&block)
    end

  end# Video


end# Rays
