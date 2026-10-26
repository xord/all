require_relative 'helper'
require 'reflex/packager/rake'


class TestPackagerRake < Test::Unit::TestCase

  include ::Rake::DSL
  include Xot::Rake
  include Reflex::Packager::Rake

  def application(&block)
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        {
          'reflex.yml' => "name: My Game\nfiles: ['lib/**/*']\n",
          'main.rb'    => '',
          'VERSION'    => '1.2.3',
          'lib/a/b.rb' => ''
        }.each do |path, text|
          FileUtils.mkdir_p File.dirname(path)
          File.write path, text
        end
        # not signed, whatever this runs with
        with_env(ENV_TO_SIGN) {block.call File.realpath(dir)}
      end
    end
  end

  def setup()
    ::Rake::Task.clear
    ::Rake::TaskManager.record_task_metadata = true # for the descriptions
  end

  def test_package_application()
    application do |dir|
      stub Gem, :win_platform?, false do
        package_application
      end
      app     = File.join dir, 'dist/adhoc/My Game.app'
      archive = File.join dir, 'dist/adhoc/MyGame-1.2.3-macos-universal.zip'
      assert_equal [app],     ::Rake::Task['package'].prerequisites
      assert_equal [archive], ::Rake::Task['archive'].prerequisites
      assert_equal [app],     ::Rake::Task[archive].prerequisites
      assert_equal [],        ::Rake::Task['release'].prerequisites # made apart on CI
      assert_equal %w[lib/a/b.rb main.rb reflex.yml VERSION].sort,
        ::Rake::Task[app].prerequisites.sort # the files of the app, not lib/a
      assert_include ::Rake::Task['package'].comment, 'dist/adhoc/My Game.app'
      assert_include ::Rake::Task['release'].comment, 'v1.2.3'

      pkg = File.join dir, 'dist/appstore/MyGame-1.2.3.pkg'
      assert_equal [pkg], ::Rake::Task['package:appstore'].prerequisites
      assert_equal ::Rake::Task[app].prerequisites, ::Rake::Task[pkg].prerequisites
      assert_include ::Rake::Task['package:appstore'].comment, 'dist/appstore/MyGame-1.2.3.pkg'
    end

    ::Rake::Task.clear
    application do
      stub Gem, :win_platform?, true do
        package_application
      end
      assert_false ::Rake::Task.task_defined?('package:appstore') # only on macos
    end
  end

  def test_release()
    application do |dir|
      archive  = File.join dir, 'dist/adhoc/MyGame-1.2.3-macos-universal.zip'
      pkg      = File.join dir, 'dist/appstore/MyGame-1.2.3.pkg'
      releases = []
      define_singleton_method(:release_on_github) {|*args, **kwargs| releases << [args, kwargs]}
      stub Gem, :win_platform?, false do
        package_application
      end
      release = -> *paths do
        paths.each {FileUtils.mkdir_p File.dirname(_1); FileUtils.touch _1}
        stub(self, :release_notes, 'notes') {::Rake::Task['release'].execute}
      ensure
        FileUtils.rm_f paths
      end

      with_env 'GITHUB_REF_NAME' => nil do
        error = assert_raise(RuntimeError) {release.call}
        assert_include error.message, 'nothing to release'
        release.call archive
        release.call pkg
        release.call archive, pkg
      end
      notes = {tag: 'v1.2.3', notes: 'notes'}
      assert_equal [[[archive], notes], [[pkg], notes], [[archive, pkg], notes]], releases

      with_env 'GITHUB_REF_NAME' => 'v9.9.9' do
        error = assert_raise(RuntimeError) {release.call archive}
        assert_include error.message, 'not the tag of the version'
      end
    end
  end

  def test_upload()
    application do |dir|
      archive = File.join dir, 'dist/adhoc/MyGame-1.2.3-macos-universal.zip'
      stub Gem, :win_platform?, false do
        package_application
      end
      assert_equal [], ::Rake::Task['upload:itchio'].prerequisites
      assert_include ::Rake::Task['upload:itchio'].comment, 'itch.io'
      out, = capture_output {::Rake::Task['upload:itchio'].execute}
      assert_include out, 'by upload.itchio'

      ::Rake::Task.clear
      File.write 'reflex.yml', "name: My Game\nupload: {itchio: {project: user/game}}\n"
      uploads  = []
      uploader = Object.new
      uploader.define_singleton_method(:upload) {|*args, **kwargs| uploads << [args, kwargs]}
      stub Gem, :win_platform?, false do
        package_application
      end
      assert_equal [archive], ::Rake::Task['upload:itchio'].prerequisites
      stub Reflex::Packager::Stores::Itchio, :new, uploader do
        # only the actions of the task, not building the zip it takes
        ::Rake::Task['upload:itchio'].execute
        error = assert_raise(RuntimeError) do
          with_env('GITHUB_ACTIONS' => 'true', 'BUTLER_API_KEY' => nil) do
            ::Rake::Task['upload:itchio'].execute
          end
        end
        assert_include error.message, 'BUTLER_API_KEY'
      end
      assert_equal [[[archive], {channel: 'macos', version: '1.2.3'}]], uploads
    end

    ::Rake::Task.clear
    application do |dir|
      pkg = File.join dir, 'dist/appstore/MyGame-1.2.3.pkg'
      stub Gem, :win_platform?, false do
        package_application
      end
      assert_equal [], ::Rake::Task['upload:appstore'].prerequisites
      assert_include ::Rake::Task['upload:appstore'].comment, 'App Store Connect'
      out, = capture_output {::Rake::Task['upload:appstore'].execute}
      assert_include out, 'by upload.appstore'

      ::Rake::Task.clear
      File.write 'reflex.yml', "name: My Game\nupload: {appstore: true}\n"
      stub Gem, :win_platform?, false do
        package_application
      end
      assert_equal [pkg], ::Rake::Task['upload:appstore'].prerequisites
      # only the actions of the task, not building the package it takes
      error = assert_raise(Reflex::Packager::Error) {::Rake::Task['upload:appstore'].execute}
      assert_include error.message, 'no API key'

      uploads  = []
      uploader = Object.new
      uploader.define_singleton_method(:upload) {|*args, **kwargs| uploads << [args, kwargs]}
      stub Reflex::Packager::Stores::AppStore, :new, uploader do
        ::Rake::Task['upload:appstore'].execute
      end
      assert_equal [[[pkg], {platform: 'macos'}]], uploads

      downloads  = []
      downloader = Object.new
      downloader.define_singleton_method(:download_metadata) {|*args, **kwargs| downloads << [args, kwargs]}
      assert_include ::Rake::Task['download:appstore:metadata'].comment, 'store/appstore'
      stub Reflex::Packager::Stores::AppStore, :new, downloader do
        ::Rake::Task['download:appstore:metadata'].execute
      end
      bundle_id = Reflex::Packager::Config.load(Reflex::Packager::REFLEX, dir).bundle_id
      assert_equal [[["#{dir}/store/appstore"], {bundle_id: bundle_id, platform: :macos}]], downloads

      ::Rake::Task.clear
      stub Gem, :win_platform?, true do
        package_application
      end
      assert_false ::Rake::Task.task_defined?('upload:appstore') # only on macos
    end
  end

  def test_notarize()
    application do
      cmds = []
      define_singleton_method(:sh) {|*args| cmds << args}
      stub Gem, :win_platform?, false do
        package_application
      end
      reflex = [RbConfig.ruby, Reflex::Packager::REFLEX.executable, 'package']
      run    = -> (task, env = {}) do
        cmds.clear
        with_env(env) {::Rake::Task[task].execute}
        cmds
      end

      assert_equal(
        [[*reflex, '--pack', '--notarize', '.']],
        run[                   'notarize'])
      assert_equal(
        [[*reflex, '--pack', '--notarize', '.']],
        run[                   'notarize', 'appstore' => 'true']) # no upload.appstore
      assert_equal(
        [[*reflex, '--pack', '--notarize-submit', '.']],
        run[                   'notarize:submit'])
      assert_equal(
        [[*reflex, '--notarize-wait',         'abc']],
        run[         'notarize:wait', 'id' => 'abc'])
      assert_equal(
        [[*reflex, '--pack', '--notarize-export', '.']],
        run[                   'notarize:export'])

      [nil, ''].each do |id|
        error = assert_raise(RuntimeError) {run['notarize:wait', 'id' => id]}
        assert_include error.message, 'id=ID'
      end

      ::Rake::Task.clear
      File.write 'reflex.yml', "name: My Game\nupload: {appstore: true}\n"
      stub Gem, :win_platform?, false do
        package_application
      end
      assert_equal(
        [[*reflex, '--pack', '--notarize', '.']],
        run[                   'notarize'])
      assert_equal(
        [[*reflex, '--pack', '--notarize', '--appstore', '.']],
        run[                   'notarize', 'appstore' => 'true'])
      assert_equal(
        [[*reflex, '--pack', '--notarize-submit', '.']],
        run[                   'notarize:submit', 'appstore' => 'false'])
      assert_equal(
        [[*reflex, '--pack', '--notarize-submit', '--appstore', '.']],
        run[                   'notarize:submit', 'appstore' => 'true'])
    end

    ::Rake::Task.clear
    application do
      stub Gem, :win_platform?, true do
        package_application
      end
      assert_false ::Rake::Task.task_defined?('notarize') # only on macos
    end
  end

  def test_release_notes()
    application do
      File.write 'ChangeLog.md', "# My Game ChangeLog\n\n\n## [v1.2.3] - 2026-10-13\n\n- Add a\n"
      with_env 'MONOREPO_COMMIT' => nil do
        stub self, :git, "abc\n" do
          assert_equal "- Add a\n\nBuilt with xord/all@abc.", release_notes('v1.2.3')
          assert_equal 'Built with xord/all@abc.',            release_notes('v9.9.9')
        end
        stub self, :git, '' do # the libraries of no checkout
          assert_equal '- Add a', release_notes('v1.2.3')
        end
      end
      with_env 'MONOREPO_COMMIT' => 'def' do
        stub self, :git, "abc\n" do
          assert_equal "- Add a\n\nBuilt with xord/all@def.", release_notes('v1.2.3')
        end
      end
    end
  end

end# TestPackagerRake
