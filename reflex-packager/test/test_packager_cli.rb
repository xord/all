require_relative 'helper'

require 'stringio'
require 'fileutils'


class TestPackagerCLI < Test::Unit::TestCase

  RP  = Reflex::Packager
  CLI = RP::CLI

  def capture(&block)
    old              = [$stdout, $stderr]
    out, err         = StringIO.new, StringIO.new
    $stdout, $stderr = out, err
    block.call
    return out.string, err.string
  ensure
    $stdout, $stderr = old
  end

  def tmpdir(&block)
    Dir.mktmpdir {|dir| Dir.chdir(dir) {block.call dir}}
  end

  def cli()
    CLI.new TEST_PROFILE
  end

  # Creates the project +name+ to package, without the Gemfile, the gems of
  # which are not installed for the tests.
  #
  def create(name)
    capture {cli.create [name]}
    FileUtils.rm File.join(name, 'Gemfile')
  end

  def test_run()
    out, = capture {cli.run []}
    assert_include out, 'Usage: reflex'

    out, = capture {cli.run ['--version']}
    assert_equal Reflex::Extension.version, out.strip

    assert_raise(SystemExit) {capture {cli.run ['unknown']}}
  end

  def test_new()
    tmpdir do
      out, = stub(Etc, :getlogin, 'someone') {capture {cli.create ['my-game']}}
      assert_include out, 'cd my-game && ruby main.rb'
      assert_equal %w[
        .github/workflows/release.yml .github/workflows/tag.yml .github/workflows/test.yml
        .gitignore .ruby-version ChangeLog.md Gemfile Rakefile VERSION
        lib/my-game.rb lib/my-game/app.rb lib/my-game/version.rb
        main.rb reflex.yml test/test_my-game.rb
      ].sort, Dir.glob('**/*', File::FNM_DOTMATCH, base: 'my-game')
        .select {File.file? File.join('my-game', _1)}.sort

      read = -> path {File.read File.join('my-game', path)}
      assert_equal "#{RP::MacOS.ruby_version}\n", read['.ruby-version']
      assert_equal "# my-game ChangeLog\n",       read['ChangeLog.md']
      assert_include read['Rakefile'],             "require 'reflex/packager/rake'"
      assert_include read['Rakefile'],             "sh 'ruby main.rb'"
      assert_include read['main.rb'],              "require 'my-game'"
      assert_include read['main.rb'],              'MyGame::App.new.start'
      assert_include read['lib/my-game.rb'],       "require 'my-game/app'"
      assert_include read['lib/my-game/app.rb'],   'class App'
      assert_include read['test/test_my-game.rb'], 'class TestMyGame'
      assert_include read['reflex.yml'],           '#developer: Your Name'
      assert_include read['reflex.yml'],           "#copyright: © #{Time.now.year} Your Name"
      Dir.glob('my-game/**/*.rb').each do |rb|
        assert_true system(RbConfig.ruby, '-c', rb, out: File::NULL), rb
      end

      config = RP::Config.load TEST_PROFILE, 'my-game'
      assert_equal 'my-game', config.name
      assert_equal '0.1.0',   config.version
      assert_equal 'main.rb', config.main
      assert_equal %w[
        VERSION lib/my-game.rb lib/my-game/app.rb lib/my-game/version.rb main.rb
      ], config.app_files
      assert_equal 'org.xord.reflex.2a59d59e.my-game', config.macos.bundle_id
    end

    tmpdir do
      capture {cli.create ['--developer', 'Some One', 'my-game']}
      config = RP::Config.load TEST_PROFILE, 'my-game'
      assert_equal 'Some One',                         config.developer
      assert_equal "© #{Time.now.year} Some One",      config.copyright
      assert_equal 'org.xord.reflex.some-one.my-game', config.macos.bundle_id
    end

    tmpdir do
      capture {cli.create ['--developer', '開発者', 'my-game']}
      config = RP::Config.load TEST_PROFILE, 'my-game'
      assert_equal '開発者',                           config.developer
      assert_equal 'org.xord.reflex.7be0c00e.my-game', config.macos.bundle_id
    end

    tmpdir do
      stub(Etc, :getlogin, 'someone') {capture {cli.create ['--developer', ' ', 'my-game']}}
      assert_include File.read('my-game/reflex.yml'), '#developer: Your Name'
      assert_equal 'org.xord.reflex.2a59d59e.my-game',
        RP::Config.load(TEST_PROFILE, 'my-game').macos.bundle_id
    end

    tmpdir do
      out, = capture {cli.create ["Bob's Game #1"]}
      assert_include out, %q(cd Bob\'s\ Game\ \#1 && ruby main.rb)
      assert_equal "Bob's Game #1", RP::Config.load(TEST_PROFILE, "Bob's Game #1").name
      assert_true system(RbConfig.ruby, '-c', "Bob's Game #1/lib/bob-s-game-1/app.rb", out: File::NULL)
    end

    tmpdir do
      assert_raise(RP::Error) {cli.create ['2d']}
      assert_raise(RP::Error) {cli.create ['string']}
      assert_raise(RP::Error) {cli.create ['reflex']}
      assert_equal [], Dir.children('.')
    end

    tmpdir do
      FileUtils.mkdir 'myapp'
      assert_raise(RP::Error) {cli.create ['myapp']}
    end

    assert_raise(RP::Error) {cli.create []}
  end

  def test_package()
    tmpdir do
      create 'myapp'
      Dir.mktmpdir do |cruby|
        saved, ENV['CRUBY_PATH'] = ENV['CRUBY_PATH'], fake_cruby(cruby)
        cli.package ['--generate-only', '--platform', 'macos', 'myapp']
      ensure
        ENV['CRUBY_PATH'] = saved
      end
      %w[project.yml src/main.mm app/main.rb].each do |f|
        assert File.exist?("myapp/.build/macos/project/#{f}"), "missing #{f}"
      end
    end

    tmpdir do
      create 'myapp'
      cli.package ['--generate-only', '--platform', 'windows', 'myapp']
      %w[src/main.cpp src/app.manifest lib/boot.rb lib/app/main.rb lib/reflex/lib/reflex.rb].each do |f|
        assert File.exist?("myapp/.build/windows/#{f}"), "missing #{f}"
      end

      cli.package ['--generate-only', '--platform', 'windows', '--pack', 'myapp']
      assert_include Dir.children('myapp/.build/windows/lib/app'), 'data.bin'
      assert_not_include Dir.children('myapp/.build/windows/lib/app'), 'main.rb'
    end

    tmpdir do
      create 'myapp'
      assert_raise(RP::Error) do
        cli.package ['--generate-only', '--platform', 'unknown', 'myapp']
      end
      error = assert_raise(RP::Error) do
        cli.package ['--notarize-submit', '--notarize-export', 'myapp']
      end
      assert_include error.message, 'only one of'

      error = assert_raise(RP::Error) do
        cli.package ['--notarize-wait', 'ID', '--appstore', 'myapp']
      end
      assert_include error.message, '--notarize-wait'
      error = assert_raise(RP::Error) do
        cli.package ['--platform', 'windows', '--appstore', 'myapp']
      end
      assert_include error.message, 'only for macos'
    end
  end

  def test_default_platform()
    stub(Gem, :win_platform?, true)  {assert_equal :windows, RP.default_platform}
    stub(Gem, :win_platform?, false) {assert_equal :macos,   RP.default_platform}
  end

end# TestPackagerCLI
