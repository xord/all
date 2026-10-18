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
        define_singleton_method(:sh) {|*args| commands << args}

        setup_monorepo 'v1', 'xot', 'rays'
        assert_include commands, ['git', 'fetch', '-q', '--depth', '1', 'https://github.com/xord/all.git', 'v1']
        assert_include commands, ['ln', '-snf', 'all/rays', '../rays']
        assert_equal   ['cd ../all/xot && rake ext', 'cd ../all/rays && rake ext'],
          commands.map {_1.first.strip}.grep(/rake ext$/)

        commands.clear
        define_singleton_method(:win32?) {true}
        define_singleton_method(:rm_rf)  {|*args| commands << [:rm_rf, *args]}
        define_singleton_method(:cp_r)   {|*args| commands << [:cp_r,  *args]}
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

end# TestRakeGitHub
