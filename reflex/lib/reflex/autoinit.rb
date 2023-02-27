# -*- coding: utf-8 -*-


require 'rays/autoinit'
require 'reflex/ext'


unless defined?($REFLEX_NOAUTOINIT) && $REFLEX_NOAUTOINIT
  Reflex.init!
  at_exit {Reflex.fin!}
end
