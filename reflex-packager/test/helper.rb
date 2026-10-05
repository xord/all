%w[../xot ../rucy ../rays ../reflex .]
  .map  {|s| File.expand_path "../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/test'
require 'reflex/extension'
require 'reflex/packager'

require 'test/unit'
require 'tmpdir'

include Xot::Test


# Makes +dir+ a checkout of the cruby repository with what packaging for macOS
# reads of it, so that the tests do not fetch the real one.
#
def fake_cruby(dir)
  %w[CRuby/include/ruby.h CRuby/lib/ruby/4.0.0/set.rb src/CRuby.m].each do |path|
    path = File.join dir, path
    FileUtils.mkdir_p File.dirname(path)
    FileUtils.touch path
  end
  dir
end


TEST_PROFILE = Reflex::Packager::Profile.new(
  pod:          'Reflex',
  git:          'https://github.com/xord/reflex',
  version:      Reflex::Extension.version,
  libraries:    %w[Xot Rucy Rays Reflex],
  extensions:   %w[rays_ext reflex_ext],
  config_files: %w[reflex.yml reflex.yaml],
  templates:    {'main.rb': <<~MAIN, 'reflex.yml': <<~CONFIG})
    require 'reflex'

    Reflex.start do
      Reflex::Window.new(title: '{{name}}', frame: [100, 100, 400, 300]).show
    end
  MAIN
    name: myapp
  CONFIG
