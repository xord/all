require_relative 'helper'


class TestPackagerLibrary < Test::Unit::TestCase

  RP = Reflex::Packager

  # Makes the gems in a directory and puts their lib/ on the load path, as
  # RUBYLIB does for the gems of a repository being worked on.
  #
  # @param gems [Hash] {dir => [gem name, dependencies, files]}
  #
  def fake_gems(gems, &block)
    Dir.mktmpdir do |root|
      gems.each do |dir, (name, deps, files)|
        FileUtils.mkdir_p File.join(root, dir)
        File.write File.join(root, dir, "#{dir}.gemspec"), <<~GEMSPEC
          Gem::Specification.new do |s|
            s.name    = '#{name}'
            s.version = '1.0'
            #{deps.map {"s.add_dependency '#{_1}'"}.join "\n  "}
          end
        GEMSPEC
        files.each do |file|
          path = File.join root, dir, file
          FileUtils.mkdir_p File.dirname(path)
          FileUtils.touch path
        end
      end
      libs = gems.keys.map {File.join root, _1, 'lib'}
      $LOAD_PATH.unshift(*libs)
      block.call root
    ensure
      $LOAD_PATH.replace $LOAD_PATH - libs.to_a
    end
  end

  def test_collect()
    gems = {
      'fakebase'   => [
        'fakebase',
        [],
        %w[lib/fakebase/extension.rb]
      ],
      # the name of the gem differs from the one of the library, as reflexion
      'fakenative' => [
        'fakenativeion',
        %w[fakebase],
        %w[lib/fakenative/extension.rb lib/fakenative/ext.rb]
      ],
      # not a library, which has no lib/*/extension.rb as reflex-packager
      'faketool'   => [
        'faketool',
        %w[fakebase],
        %w[lib/faketool.rb]
      ],
      'fakeapp'    => [
        'fakeapp',
        %w[faketool fakenativeion no-such-gem],
        %w[lib/fakeapp/extension.rb]
      ]
    }
    fake_gems gems do |root|
      libs = RP::Library.collect File.join(root, 'fakeapp')
      assert_equal %w[fakebase fakenative fakeapp],    libs.map(&:name)
      assert_equal [nil, 'fakenative_ext', nil],       libs.map(&:extension)
      assert_equal libs.map {File.join root, _1.name}, libs.map(&:root)

      # leaving out the ones collected already
      libs = RP::Library.collect File.join(root, 'fakeapp'), known: libs.first(1)
      assert_equal %w[fakenative fakeapp], libs.map(&:name)
    end
  end

  def test_collect_the_libraries_of_the_profiles()
    # this repository, which the helper puts on the load path
    assert_equal %w[xot rucy rays reflex], TEST_PROFILE.libraries.map(&:name)
    assert_equal %w[rays_ext reflex_ext],  TEST_PROFILE.extensions
  end

end# TestPackagerLibrary
