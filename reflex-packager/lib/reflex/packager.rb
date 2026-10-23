require 'reflex/packager/extension'

require 'reflex/packager/data_file'
require 'reflex/packager/data_compiler'
require 'reflex/packager/data_loader'

require 'reflex/packager/profile'
require 'reflex/packager/config'
require 'reflex/packager/platform'
require 'reflex/packager/gems'
require 'reflex/packager/app_store_connect'
require 'reflex/packager/macos'
require 'reflex/packager/windows'
require 'reflex/packager/stores/app_store'
require 'reflex/packager/stores/itchio'
require 'reflex/packager/cli'


module Reflex::Packager

  PLATFORMS = {macos: MacOS, windows: Windows}

  # The platform the packager runs on, the only one it can build for.
  #
  def self.default_platform()
    Gem.win_platform? ? :windows : :macos
  end

end
