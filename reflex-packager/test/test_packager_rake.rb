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
      app     = File.join dir, 'dist/adhoc/MyGame.app'
      archive = File.join dir, 'dist/adhoc/MyGame-1.2.3-macos-universal.zip'
      assert_equal [app],     ::Rake::Task['package'].prerequisites
      assert_equal [archive], ::Rake::Task['archive'].prerequisites
      assert_equal [app],     ::Rake::Task[archive].prerequisites
      assert_equal [archive], ::Rake::Task['release'].prerequisites
      assert_equal %w[lib/a/b.rb main.rb reflex.yml VERSION].sort,
        ::Rake::Task[app].prerequisites.sort # the files of the app, not lib/a
      assert_include ::Rake::Task['package'].comment, 'dist/adhoc/MyGame.app'
      assert_include ::Rake::Task['release'].comment, 'v1.2.3'
    end
  end

  def test_upload_itchio()
    application do |dir|
      archive = File.join dir, 'dist/adhoc/MyGame-1.2.3-macos-universal.zip'
      stub Gem, :win_platform?, false do
        package_application
      end
      assert_equal [archive], ::Rake::Task['upload:itchio'].prerequisites
      assert_include ::Rake::Task['upload:itchio'].comment, 'itch.io'
      # only the actions of the task, not building the zip it takes
      error = assert_raise(RuntimeError) {::Rake::Task['upload:itchio'].execute}
      assert_include error.message, 'upload.itchio.project'

      ::Rake::Task.clear
      File.write 'reflex.yml', "name: My Game\nupload: {itchio: {project: user/game}}\n"
      uploads  = []
      uploader = Object.new
      uploader.define_singleton_method(:upload) {|*args, **kwargs| uploads << [args, kwargs]}
      stub Gem, :win_platform?, false do
        package_application
        stub Reflex::Packager::Stores::Itchio, :new, uploader do
          ::Rake::Task['upload:itchio'].execute
        end
      end
      assert_equal [[[archive], {channel: 'macos', version: '1.2.3'}]], uploads
    end
  end

  def test_release_notes()
    application do
      File.write 'ChangeLog.md', "# My Game ChangeLog\n\n\n## [v1.2.3] - 2026-10-13\n\n- Add a\n"
      stub self, :git, "abc\n" do
        assert_equal "- Add a\n\nBuilt with xord/all@abc.", release_notes('v1.2.3')
        assert_equal 'Built with xord/all@abc.',           release_notes('v9.9.9')
      end
      stub self, :git, '' do # the libraries of no checkout
        assert_equal '- Add a', release_notes('v1.2.3')
      end
    end
  end

end# TestPackagerRake
