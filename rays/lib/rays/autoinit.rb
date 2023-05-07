require 'rays/ext'


unless defined?($RAYS_NOAUTOINIT) && $RAYS_NOAUTOINIT
  Rays.init!
  at_exit {Rays.fin!}
end
