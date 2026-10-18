require_relative 'helper'
require 'xot/rake'


class TestRakeGitHub < Test::Unit::TestCase

  include Rake::DSL
  include Xot::Rake

  def test_dependency_names()
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        File.write 'Rakefile', <<~END
          require 'xot/rake'

          require 'xot/extension'
          require "rucy/extension"
          require 'reflex/extension'
          # require 'rays/extension'
        END
        FileUtils.mkdir_p 'lib/reflex'
        FileUtils.touch   'lib/reflex/extension.rb'
        assert_equal %w[xot rucy], dependency_names # but the one of this
      end
    end
  end

  def test_setup_monorepo()
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p %W[#{dir}/app #{dir}/all]
      Dir.chdir "#{dir}/app" do
        commands = []
        win32    = false
        define_singleton_method(:sh)     {|*args| commands << args}
        define_singleton_method(:rm_rf)  {|*args| commands << [:rm_rf, *args]}
        define_singleton_method(:cp_r)   {|*args| commands << [:cp_r,  *args]}
        define_singleton_method(:win32?) {win32} # whatever the platform running this

        setup_monorepo 'v1', 'xot', 'rays'
        assert_include commands,
          ['git', 'fetch', '-q', '--depth', '1', 'https://github.com/xord/all.git', 'v1']
        assert_include commands, ['ln', '-snf', 'all/rays', '../rays']
        assert_equal   ['cd ../all/xot && rake ext', 'cd ../all/rays && rake ext'],
          commands.map {_1.first.strip}.grep(/rake ext$/)

        commands.clear
        win32 = true
        setup_monorepo 'v1', 'rays'
        assert_equal [
          'cd ../all/rays && rake ext',
          [:rm_rf, '../rays'],
          [:cp_r,  '../all/rays', '../rays']
        ], commands.last(3).map {_1.first.is_a?(String) ? _1.first.strip : _1}

        assert_raise(RuntimeError) {setup_monorepo 'master'}
      end
    end
  end

  def test_setup_mesa()
    Dir.mktmpdir do |dir|
      commands = []
      define_singleton_method(:sh) {|*args| commands << args}
      env, ENV['GITHUB_ENV'] = ENV['GITHUB_ENV'], File.join(dir, 'env')

      setup_mesa '1.2.3'
      assert_equal [
        ['curl', '-sSfL', '-o', 'mesa.7z',
          'https://github.com/pal1000/mesa-dist-win/releases/download/1.2.3/mesa3d-1.2.3-release-msvc.7z'],
        ['7z', 'x', 'mesa.7z'],
        ['powershell.exe', '.\\systemwidedeploy.cmd', '1']
      ], commands
      assert_equal "GALLIUM_DRIVER=llvmpipe\n", File.read(ENV['GITHUB_ENV'])
    ensure
      ENV['GITHUB_ENV'] = env
    end
  end

end# TestRakeGitHub
