require 'reflex/packager/extension'

require 'reflex/packager/profile'
require 'reflex/packager/config'
require 'reflex/packager/platform'
require 'reflex/packager/macos'
require 'reflex/packager/cli'


module Reflex::Packager
  PLATFORMS = {macos: MacOS}
end
