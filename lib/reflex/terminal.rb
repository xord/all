require 'xot/const_symbol_accessor'
require 'reflex/ext'
require 'reflex-terminal/ext'


module Reflex


  class Terminal

    def initialize(
      columns = 80, rows = 24,
      # a memory budget rather than a line count: how many lines fit
      # depends on how wide the terminal is. 0 keeps no scrollback
      scrollback_bytes: 8 * 1024 * 1024)

      initialize! columns, rows, scrollback_bytes
    end

    def resize(
      columns, rows,
        cell_width: 8,   cell_height: 16,
      screen_width: 0, screen_height: 0)

      resize! columns, rows, cell_width, cell_height, screen_width, screen_height
    end

    # Starts a child process on a new pseudo terminal.
    #
    # Follows the Kernel#spawn convention: a leading hash sets environment
    # variables (a nil value removes one), a single string runs via the
    # shell (so quoting and pipes work), and multiple arguments exec
    # directly. Unlike Kernel#spawn, unsetenv_others is not supported.
    #
    # @return [self] self
    #
    def spawn(*args)
      envs = args.first.is_a?(Hash) ? args.shift : {}
      args = args.compact
      args = ['/bin/sh', '-c', args.first] if args.size == 1
      spawn! args, envs
    end

    # Yields each style span of the visible screen.
    #
    # @yield [x, y, width, text, fg, bg, flags] a run of cells sharing
    #   the same style; x, y and width are in cells, and fg/bg are
    #   0xRRGGBB or nil for the terminal's default color
    #
    # @return [Enumerator] when no block is given
    #
    def each_span(&block)
      return enum_for :each_span unless block
      each_span!(&block)
    end

    const_symbol_accessor :option_as_alt, **{
      off:   OPTION_AS_ALT_OFF,
      on:    OPTION_AS_ALT_ON,
      left:  OPTION_AS_ALT_LEFT,
      right: OPTION_AS_ALT_RIGHT
    }

  end# Terminal


end# Reflex
