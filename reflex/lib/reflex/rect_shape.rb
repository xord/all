require 'xot/universal_accessor'
require 'reflex/shape'


module Reflex


  class RectShape < Shape

    universal_accessor :nsegment, :round,
      :round_left_top,    :round_right_top,
      :round_left_bottom, :round_right_bottom

  end# RectShape


end# Reflex
