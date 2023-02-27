# -*- coding: utf-8 -*-


require 'xot/bit_flag'
require 'xot/block_util'


module Xot


  module BitFlagAccessor

    def bit_flag_accessor(name, bit_flag = nil, **flags, &block)
      bf = define_bit_flag name, bit_flag, flags, block
      define_bit_flag_writer name, bf
      define_bit_flag_reader name, bf
    end

    def bit_flag_writer(name, bit_flag = nil, **flags, &block)
      define_bit_flag_writer name, define_bit_flag(name, bit_flag, flags, block)
    end

    def bit_flag_reader(name, bit_flag = nil, **flags, &block)
      define_bit_flag_reader name, define_bit_flag(name, bit_flag, flags, block)
    end

    private

      def define_bit_flag(name, bit_flag, flags, block)
        bit_flag ||= Xot::BitFlag.new(**flags)
        Xot::BlockUtil.instance_eval_or_block_call bit_flag, &block if block

        define_singleton_method "#{name}_flag".intern do
          bit_flag
        end

        bit_flag
      end

      def define_bit_flag_writer(name, bit_flag)
        writer = "#{name}=".intern
        setter = "bf_set_#{name}__".intern

        alias_method setter, writer
        private setter

        define_method writer do |*symbols|
          __send__ setter, bit_flag.symbols2bits(symbols)
        end

        name
      end

      def define_bit_flag_reader(name, bit_flag)
        reader = name.intern
        getter = "bf_get_#{name}__".intern

        alias_method getter, reader
        private getter

        define_method reader do
          bit_flag.bits2symbols __send__(getter)
        end

        name
      end

  end# BitFlagAccessor


end# Xot


class Module

  include Xot::BitFlagAccessor

end# Module
