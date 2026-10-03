require 'reflex/ext'
require 'reflex/window'


module Reflex


  extend module ClassMethods

    def start(*args, &block)
      Application.new(*args, &block).start
    end

    def quit()
      Application.instance.quit
    end

    def window(*args, &block)
      Window.new(*args, &block).tap {|w| w.show}
    end

    def alert(message, title: nil)
      utf8 = -> s {s.to_s.encode Encoding::UTF_8, invalid: :replace, undef: :replace}
      alert! utf8[message], title&.then(&utf8)
    end

    self

  end# ClassMethods


end# Reflex
