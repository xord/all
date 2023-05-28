require 'forwardable'


module Reflex


  class Screen

    extend Forwardable

    def_delegators :frame,
      :x, :y, :z, :w, :h, :d, :width, :height, :depth,
      :left, :top, :back, :right, :bottom, :front,
      :left_top, :right_top, :left_bottom, :right_bottom,
      :lt, :lr, :lb, :rb,
      :position, :pos, :size, :center

  end# Screen


end# Reflex
