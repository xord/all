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
  # as a package does, with +libs+ on the load path.
  #
  def run_app(files = APP, libs: {}, ruby_version: nil)
    Dir.mktmpdir do |dir|
      File.write File.join(dir, 'outside.txt'), 'outside' # beside the app
      lib = File.join dir, 'lib'
      dir = File.join dir, 'app'
      libs.each {|name, content| FileUtils.mkdir_p lib; File.write File.join(lib, name), content}
      files.each do |name, content|
        path = File.join dir, name
        FileUtils.mkdir_p File.dirname(path)
        File.binwrite path, content
      end
      RP::Platform.pack_app dir
      yield dir if block_given?
      if ruby_version
        RP::DataFile.open(File.join dir, 'data.bin') do |data|
          RP::DataFile.write data.path, data.names.to_h {[_1, data.read(_1)]}
            .merge('.ruby-version' => ruby_version)
        end
      end

      script = <<~RUBY
        load #{File.join(LIB_DIR, 'data_file.rb').dump}
        load #{File.join(LIB_DIR, 'data_loader.rb').dump}
        Dir.chdir #{dir.dump}
        $LOAD_PATH.unshift Dir.pwd, #{lib.dump}
        Reflex::Packager::DataLoader.setup Dir.pwd
        load 'main.rb'
      RUBY
      IO.popen [RbConfig.ruby, '-e', script], err: [:child, :out], &:read
    end
  end

  def test_pack_app()
    run_app do |dir|
      assert_equal ['data.bin'], Dir.children(dir)
      RP::DataFile.open File.join(dir, 'data.bin') do |data|
        assert_equal %w[.ruby-version foo.rbc image.png lib/bar.rbc lib/baz.rbc main.rbc once.rbc],
          data.names.sort
        assert_equal RUBY_VERSION, data.read('.ruby-version')
        assert_equal "\x89PNG".b,  data.read('image.png')
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
        r << File.read('data/a.txt').encoding.to_s
        r << File.read('data/a.txt', 2, 1)
        r << File.read('data/a.txt', mode: 'rb').encoding.to_s
        r << File.binread('data/a.txt').encoding.to_s
        r << [File.exist?('data/a.txt'), File.file?('data/a.txt'), File.exist?('data'), File.directory?('data'), Dir.exist?('data')]
        r << [File.exist?('main.rb'), File.exist?('none.txt'), File.file?('data'), File.directory?('data/a.txt')]
        r << File.open('data/a.txt') {_1.read}
        r << File.open('data/a.txt', 'rb').read.encoding.to_s
        r << File.open('data/a.txt', mode: 'rb').read.encoding.to_s
        r << File.open(__FILE__.sub('main.rb', '../outside.txt'), mode: 'rb') {_1.read}
        File.write 'out.txt', 'written'
        r << File.read('out.txt')
        r << Dir.glob('*')
        r << Dir.glob('**/*.txt')
        r << Dir['data/*']
        r << Dir.glob('*', base: 'data')
        r << Dir.glob(File.expand_path 'data/*.txt').map {_1.delete_prefix Dir.pwd}
        require 'rays'
        path, bytes, smooth = Rays::Image.load 'data/b.png', smooth: true
        r << [path.start_with?(Dir.pwd), bytes.unpack1('H*'), smooth, Rays::Image.load('data/b.png').first == path]
        require 'beeps'
        path = Beeps::FileIn.new('data/b.png').path
        r << [path.start_with?(Dir.pwd), File.binread(path).unpack1('H*')]
        p r
      RUBY
      'data/a.txt' => 'abc',
      'data/b.png' => "\x89PNG".b
    }
    rays = <<~RUBY
      module Rays
        class Image
          def self.load(path, smooth: false) = [path, File.binread(path), smooth]
        end
      end
    RUBY
    beeps = <<~RUBY
      module Beeps
        class FileIn
          attr_accessor :path
          def initialize(path) = self.path = path
        end
      end
    RUBY
    assert_equal [
      'abc', 'UTF-8', 'bc', 'ASCII-8BIT', 'ASCII-8BIT',
      [true,  true,  true,  true,  true],
      [false, false, false, false],
      'abc', 'ASCII-8BIT', 'ASCII-8BIT',
      'outside', # out of the app directory as it is
      'written',
      %w[data out.txt],
      %w[data/a.txt out.txt],
      %w[data/a.txt data/b.png],
      %w[a.txt b.png],
      %w[/data/a.txt], # as absolute as the pattern
      [false, '89504e47', true, true], # extracted to a temporary file once
      [false, '89504e47']
    ], eval(run_app files, libs: {'rays.rb' => rays, 'beeps.rb' => beeps})
  end

  def test_ruby_version()
    assert_match(/data file is for Ruby 0\.0\.0, not #{Regexp.escape RUBY_VERSION}/,
      run_app(ruby_version: '0.0.0'))
  end

end# TestPackagerDataLoader
