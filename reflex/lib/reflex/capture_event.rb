require 'reflex/ext'
require 'reflex/view'


module Reflex


  class CaptureEvent < Event

    def begin()
      View.capture_flag.bits2symbols get_begin
    end

    def begin?(*symbols)
      bits = View.capture_flag.symbols2bits(*symbols)
      (bits & get_begin) == bits
    end

    def end()
      View.capture_flag.bits2symbols get_end
    end

    def end?(*symbols)
      bits = View.capture_flag.symbols2bits(*symbols)
      (bits & get_end) == bits
    end

    def inspect()
      "#<Reflex::CaptureEvent begin:#{self.begin} end:#{self.end}}>"
    end

  end# CaptureEvent


end# Reflex
