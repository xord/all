# -*- coding: utf-8 -*-


module Xot


  module ConstSymbolAccessor

    def const_symbol_accessor(name, **symbol2const)
      const_symbol_writer name, **symbol2const
      const_symbol_reader name, **symbol2const
    end

    def const_symbol_writer(name, **symbol2const)
      writer = "#{name}=".intern
      setter = "cs_set_#{name}__".intern

      alias_method setter, writer
      private setter

      define_method writer do |symbol|
        const = symbol2const[symbol]
        raise ArgumentError unless const
        __send__ setter, const
      end

      name
    end

    def const_symbol_reader(name, **symbol2const)
      reader = name.intern
      getter = "cs_get_#{name}__".intern

      alias_method getter, reader
      private getter

      const2symbol = symbol2const.reduce({}) {|h, (k, v)| h[v] = k; h}

      define_method reader do
        const  = __send__ getter
        symbol = const2symbol[const]
        raise "'#{const}' is unknown value." unless symbol
        symbol
      end

      name
    end

  end# ConstSymbolAccessor


end# Xot


class Module

  include Xot::ConstSymbolAccessor

end# Module
