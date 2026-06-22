%w[../xot ../rucy ../rays ../reflex .]
  .map  {|s| File.expand_path "../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/test'
require 'reflex/extension'
require 'reflex/packager'

require 'test/unit'
require 'tmpdir'

include Xot::Test


TEST_PROFILE = Reflex::Packager::Profile.new(
  pod:          'Reflex',
  git:          'https://github.com/xord/reflex',
  version:      Reflex::Extension.version,
  libraries:    %w[Xot Rucy Rays Reflex],
  extensions:   %w[rays_ext reflex_ext],
  config_files: %w[reflex.yml reflex.yaml],
  template:     <<~RUBY)
    require 'reflex'

    Reflex.start do
      Reflex::Window.new(title: '{{name}}', frame: [100, 100, 400, 300]).show
    end
  RUBY
