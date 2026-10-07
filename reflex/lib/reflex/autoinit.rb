# load reflex_ext before Rays.init! to set pre_init_fun
require 'reflex/ext'

require 'rays/autoinit'


unless defined?($REFLEX_NOAUTOINIT) && $REFLEX_NOAUTOINIT
  Reflex.init!
  at_exit {Reflex.fin!}
end
