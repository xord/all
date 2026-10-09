require 'reflex/packager/extension'

require 'reflex/packager/data_file'

require 'reflex/packager/profile'
require 'reflex/packager/config'
require 'reflex/packager/platform'
require 'reflex/packager/gems'
require 'reflex/packager/macos'
require 'reflex/packager/windows'
require 'reflex/packager/cli'


module Reflex::Packager
  PLATFORMS = {macos: MacOS, windows: Windows}
end
