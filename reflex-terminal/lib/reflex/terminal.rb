require 'xot/util'
require 'xot/const_symbol_accessor'
require 'reflex-terminal/ext'


module Reflex


  class Terminal

    HISTORY_CHUNK_SIZE = 500

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
      args = shell_command(args.first) if args.size == 1
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

    # Yields each line of the visible screen.
    #
    # @yield [line] a row of the screen, without its trailing spaces and
    #   without a newline of its own
    #
    # @return [Enumerator] when no block is given
    #
    def each_line(&block)
      return enum_for :each_line unless block
      each_line!(&block)
    end

    # @return [Array<String>] the visible screen, one string per row
    #
    def lines()
      each_line.to_a
    end

    # Yields each line of the scrollback, oldest first.
    #
    # The history is walked in chunks rather than handed over at once,
    # since it can hold far more than fits in memory.
    #
    # @yield [line] a line of the history, without its trailing spaces
    #
    # @return [Enumerator] when no block is given
    #
    def each_history_line(&block)
      return enum_for :each_history_line unless block
      (0...history_rows).step HISTORY_CHUNK_SIZE do |row|
        get_history_lines!(row, HISTORY_CHUNK_SIZE).each(&block)
      end
      self
    end

    const_symbol_accessor :option_as_alt, **{
      off:   OPTION_AS_ALT_OFF,
      on:    OPTION_AS_ALT_ON,
      left:  OPTION_AS_ALT_LEFT,
      right: OPTION_AS_ALT_RIGHT
    }

    private

    def shell_command(command)
      if Xot.win32?
        [ENV['COMSPEC'] || 'cmd.exe', '/c', command]
      else
        ['/bin/sh', '-c', command]
      end
    end

  end# Terminal


end# Reflex
