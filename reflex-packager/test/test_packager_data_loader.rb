require_relative 'helper'


class TestPackagerDataLoader < Test::Unit::TestCase

  RP = Reflex::Packager

  LIB_DIR = File.expand_path '../lib/reflex/packager', __dir__

  APP = {
    'main.rb' => <<~RUBY,
      $log = []
      $log << require('foo')
      $log << require('foo')
      require_relative 'lib/bar'
      load 'once.rb'
      load 'once.rb'
      $log << require('shellwords') # from the files
      $log << [__FILE__, __dir__]
      $log << $LOADED_FEATURES.grep(/\\/(foo|lib\\/ba[rz])\\.rb\\z/).map {File.basename _1}
      p $log
    RUBY
    'foo.rb'     => '$log << :foo',
    'lib/bar.rb' => "require_relative 'baz'; $log << [:bar, __FILE__]",
    'lib/baz.rb' => '$log << :baz',
    'once.rb'    => '$log << :once',
    'image.png'  => "\x89PNG".b
  }

  # Packs +files+ as an app, and runs the main script of it in another Ruby,
  # as a package does.
  #
  def run_app(files = APP, ruby_version: nil)
    Dir.mktmpdir do |dir|
      src = File.join dir, 'src'
      dir = File.join dir, 'app'
      files.each do |name, content|
        path = File.join src, name
        FileUtils.mkdir_p File.dirname(path)
        File.binwrite path, content
      end
      RP::Platform.pack_app src, dir
      yield src, dir if block_given?
      if ruby_version
        RP::DataFile.open(File.join dir, 'data.bin') do |data|
          RP::DataFile.write data.path, data.names.to_h {[_1, data.read(_1)]}
            .merge('.ruby-version' => ruby_version)
        end
      end

      script = <<~RUBY
        require #{File.join(LIB_DIR, 'data_loader.rb').dump} # with data_file.rb beside
        Dir.chdir #{dir.dump}
        $LOAD_PATH.unshift Dir.pwd
        Reflex::Packager::DataLoader.setup Dir.pwd
        load 'main.rb'
      RUBY
      IO.popen [RbConfig.ruby, '-e', script], err: [:child, :out], &:read
    end
  end

  def test_pack_app()
    run_app do |src, dir|
      assert_equal APP.keys.sort,  Dir.glob('**/*.*', base: src).sort # as they are
      assert_equal %w[data.bin image.png], Dir.children(dir).sort # the others as they are
      assert_equal "\x89PNG".b, File.binread(File.join dir, 'image.png')
      RP::DataFile.open File.join(dir, 'data.bin') do |data|
        assert_equal %w[.ruby-version foo.rbc lib/bar.rbc lib/baz.rbc main.rbc once.rbc],
          data.names.sort
        assert_equal RUBY_VERSION, data.read('.ruby-version')
        assert_not_include data.read('main.rbc'), '$log << require' # compiled
      end
    end
  end

  def test_require()
    log = eval run_app
    assert_equal [
      :foo, true, false,
      :baz, [:bar, 'lib/bar.rb'],
      :once, :once,
      true,
      ['main.rb', '.'],
      %w[foo.rb bar.rb baz.rb] # each before it runs, for one it requires to require it back
    ], log
  end

  def test_files()
    files = {
      'main.rb' => <<~RUBY,
        r = []
        r << File.read('data/a.txt')
        r << Dir.glob('**/*').sort # with none of the scripts
        r << [File.exist?('main.rb'), File.exist?('sub.rb')]
        r << require_relative('sub')
        p r
      RUBY
      'sub.rb'     => '',
      'data/a.txt' => 'abc'
    }
    assert_equal [
      'abc',
      %w[data data.bin data/a.txt],
      [false, false],
      true
    ], eval(run_app files)
  end

  def test_ruby_version()
    assert_match(/data file is for Ruby 0\.0\.0, not #{Regexp.escape RUBY_VERSION}/,
      run_app(ruby_version: '0.0.0'))
  end

end# TestPackagerDataLoader
