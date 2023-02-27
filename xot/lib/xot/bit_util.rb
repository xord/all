# -*- coding: utf-8 -*-


module Xot


  module BitUtil

    module_function

    def bit(*bits)
      return nil if bits.compact.empty?
      bits.reduce(0) {|value, nth| value | (0x1 << nth)}
    end

  end# BitUtil


end# Xot
