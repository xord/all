# -*- coding: utf-8 -*-


require 'xot/invoker'
require 'xot/setter'
require 'xot/block_util'
require 'reflex/color'


module Reflex


  class Model

    include Enumerable
    include Xot::Invoker
    include Xot::Setter

    attr_reader :data

    def initialize(data = nil, &block)
      self.data = data if data
      Xot::BlockUtil.instance_eval_or_block_call self, &block if block
    end

    def data=(data)
      skip, data = apply_filters(data).tap do |filtered|
        skip = filtered.nil? && !data.nil?
        break skip, filtered
      end
      if !skip && data != @data
        @data = data
        invoke :update
      end
      @data
    end

    def add_handler(handler)
      super
      invoke :attach, {}, only: handler
    end

    def remove_handler(handler)
      invoke :detach, {}, only: handler
      super
    end

    def invoke(name, attributes = {}, options = {})
      attributes[:data] ||= @data
      super "on_data_#{name}".intern, attributes, options
    end

    def add_filter(&block)
      (@filters ||= []).push block
    end

    def remove_filter(&block)
      @filters.delete block if @filters
    end

    alias filter add_filter

    def validate(&block)
      filter {|data| block.call(data) ? data : nil}
    end

    def min=(min)
      filter {|data| data < min ? min : data}
    end

    def max=(max)
      filter {|data| data > max ? max : data}
    end

    def minmax=(range)
      min, max = range.min, range.max
      filter {|data| data < min ? min : data > max ? max : data}
    end

    def int(defvar = nil)
      call_symbols INT_SYMS
    end

    def float(defvar = nil)
      call_symbols FLOAT_SYMS
    end

    def string(defvar = nil)
      call_symbols STRING_SYMS
    end

    def [](*args)
      call_symbols ARRAY_GET_SYMS, *args
    end

    def []=(*args)
      ret = call_symbols ARRAY_SET_SYMS, *args
      invoke :update
      ret
    end

    def size()
      call_symbols(ARRAY_SIZE_SYMS) || 0
    end

    def each(&block)
      data.each(&block) if block && data.respond_to?(:each)
    end

    def inspect()
      "#<Model data:#{@data.inspect}>"
    end

    private

      INT_SYMS       = [:to_i, :to_int]

      FLOAT_SYMS     = [:to_f, :to_float]

      STRING_SYMS    = [:to_s, :to_str, :to_string]

      ARRAY_GET_SYMS = [:[], :at]

      ARRAY_SET_SYMS = [:[]=, :set_at]

      ARRAY_SIZE_SYMS = [:size, :length]

      def apply_filters(data)
        return data unless @filters
        @filters.each do |filter|
          break if data.nil?
          data = filter.call data
        end
        data
      end

      def call_symbols(symbols, *args)
        if dat = data
          symbols.each do |symbol|
            return dat.send symbol, *args if dat.respond_to? symbol
          end
        end
        nil
      end

  end# Model


end# Reflex
