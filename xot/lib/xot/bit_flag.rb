# -*- coding: utf-8 -*-


require 'xot/bit_util'


module Xot


  class BitFlag

    include BitUtil

    alias make_bit bit

    def initialize(auto: false, none: 0, **flags, &block)
      @bit2sym, @sym2bit, @auto, @next = {}, {none: none, no: none}, auto, 1
      flags.each {|sym, value| flag sym, value}
      BlockUtil.instance_eval_or_block_call self, &block if block
    end

    def flag(symbol, value = nil, bit: nil)
      bit = value || make_bit(bit) || (@auto ? @next : nil)

      raise ArgumentError if !bit
      raise "flag: symbol #{symbol.inspect} or bit #{bit} is already registered." if
        @sym2bit.key?(symbol) || @bit2sym.key?(bit)

      single_bit = bit.to_s(2).count('1') == 1

      @sym2bit[symbol] = bit
      @bit2sym[bit]    = symbol   if single_bit
      @next            = bit << 1 if single_bit && bit >= @next

      bit
    end

    def bits2symbols(bits)
      array = []
      bits.to_s(2).reverse.each_char.with_index do |char, index|
        next unless char == '1'
        symbol = @bit2sym[bit index]
        raise "unknown bit #{index} for flag." unless symbol
        array << symbol
      end
      array
    end

    def symbols2bits(*symbols)
      symbols.flatten.reduce(0) {|value, symbol| value | sym2bit(symbol)}
    end

    private

      def sym2bit(symbol)
        bit = @sym2bit[symbol]
        bit = flag symbol if !bit && @auto
        raise "unknown symbol #{symbol.inspect} for flag." unless bit
        bit
      end

  end# BitFlag


end# Xot
