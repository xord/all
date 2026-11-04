require 'reflex/extension'
require 'reflex/packager/profile'


module Reflex


  module Packager


    # The profile to package an app of Reflex with.
    #
    REFLEX = Profile.new(
      extension:    Reflex::Extension,
      config_files: %w[reflex.yml reflex.yaml],
      templates:    File.expand_path('../templates/new/reflex', __dir__),
      rake:         'reflex/packager/rake',
      executable:   File.expand_path('../../../../bin/reflex', __dir__))


  end# Packager


end# Reflex
