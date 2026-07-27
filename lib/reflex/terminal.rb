require 'reflex/ext'
require 'reflex-terminal/ext'


module Reflex


  class Terminal

    def initialize(columns = 80, rows = 24, scrollback: 10_000)
      initialize! columns, rows, scrollback
    end

    def resize(
      columns, rows,
        cell_width: 8,   cell_height: 16,
      screen_width: 0, screen_height: 0)

      resize! columns, rows, cell_width, cell_height, screen_width, screen_height
    end

  end# Terminal


end# Reflex
