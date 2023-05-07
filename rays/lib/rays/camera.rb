require 'xot/block_util'
require 'rays/ext'


module Rays


  class Camera

    def initialize(
      min_width = -1, min_height = -1,
      device_name: nil, resize: true, crop: true, &block)

      setup device_name, min_width, min_height, resize, crop
      Xot::BlockUtil.instance_eval_or_block_call self, &block if block
    end

  end# Camera


end# Rays
