%w[../xot ../rucy ../rays ../reflex .]
  .map  {|s| File.expand_path "../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/test'
require 'reflex/extension'
require 'reflex/packager'

require 'test/unit'
require 'tempfile'
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

# Runs the block with the method +name+ of +obj+ returning +value+.
#
def stub(obj, name, value, &block)
  # removed before defined again, which warns on overwriting
  klass  = obj.singleton_class
  hidden = klass.private_method_defined? name, false
  saved  = klass.instance_method name if hidden || klass.method_defined?(name, false)
  klass.remove_method name if saved
  klass.define_method(name) {|*| value}
  block.call
ensure
  klass.remove_method name
  klass.define_method name, saved if saved
  klass.send :private, name       if hidden
end

# Runs the block with the environment variables of +env+, nil to unset.
#
def with_env(env, &block)
  saved = env.map {|key, _| [key, ENV[key]]}
  env.each {|key, value| value ? ENV[key] = value : ENV.delete(key)}
  block.call
ensure
  saved.each {|key, value| value ? ENV[key] = value : ENV.delete(key)}
end


TEST_PROFILE = Reflex::Packager::Profile.new(
  extension:    Reflex::Extension,
  config_files: %w[reflex.yml reflex.yaml],
  templates:    {'main.rb': <<~MAIN, 'reflex.yml': <<~CONFIG})
    require 'reflex'

    Reflex.start do
      Reflex::Window.new(title: '{{name}}', frame: [100, 100, 400, 300]).show
    end
  MAIN
    name: myapp
  CONFIG

# The environment variables to sign with, to unset by with_env for the tests
# not to take the ones of the developer.
#
ENV_TO_SIGN = [
  *Reflex::Packager::MacOSConfig::CODESIGN_ENV_KEYS.values,
  *Reflex::Packager::MacOS::AUTH_ENV_KEYS.values
].to_h {[_1, nil]}
