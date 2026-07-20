require 'forwardable'
require 'xot/hookable'
require 'xot/block_util'
require 'reflex/ext'


module Reflex


  class Menu

    include Enumerable
    include Xot::Hookable

    def initialize(label = nil, &block)
      super()
      self.label = label if label
      Xot::BlockUtil.instance_eval_or_block_call self, &block if block
    end

    def add_child(child, index: nil)
      add_child! child, index
    end

    alias add       add_child
    alias remove remove_child

    def enable(bool = true)
      enable! bool
    end

    def disable()
      enable! false
    end

    def check(bool = true)
      check! bool
    end

    def uncheck()
      check! false
    end

    def shortcut=(key_and_modifiers)
      key, *mods = key_and_modifiers
      self.shortcut_key       = key
      self.shortcut_modifiers = mods
    end

    bit_flag_accessor :shortcut_modifiers do
      flag :shift,   MOD_SHIFT
      flag :control, MOD_CONTROL
      flag :alt,     MOD_ALT
      flag :command, MOD_COMMAND
      flag :option,  MOD_OPTION
    end

    def each(&block)
      return enum_for :each unless block
      each!(&block)
    end

    def children()
      to_a
    end

    def inspect()
      "#<Reflex::Menu label:#{label.inspect} size:#{size}>"
    end

  end# Menu


end# Reflex
