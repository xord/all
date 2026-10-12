%w[.]
  .map  {|s| File.expand_path "../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot'
require 'xot/test'
require_relative '../ext/xot/tester'

require 'fileutils'
require 'tmpdir'
require 'test/unit'

include Xot::Test


module GitRepo

  GIT_ENV = {
    'GIT_CONFIG_GLOBAL'   => File::NULL,
    'GIT_CONFIG_NOSYSTEM' => '1',
    'GIT_AUTHOR_NAME'     => 'test',
    'GIT_AUTHOR_EMAIL'    => 'test@example.com',
    'GIT_COMMITTER_NAME'  => 'test',
    'GIT_COMMITTER_EMAIL' => 'test@example.com'
  }

  CHANGELOG = "# app ChangeLog\n\n\n## [v0.1.0] - 2026-10-01\n\n- First\n"

  def repo(&block)
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        with_env GIT_ENV do
          git! 'init', '-q'
          commit 'Start', 'VERSION' => '0.1.0', 'ChangeLog.md' => CHANGELOG
          block.call dir
        end
      end
    end
  end

  def commit(message, files = {})
    files.each do |path, text|
      FileUtils.mkdir_p File.dirname(path)
      File.write path, text
    end
    git! 'add', '-A'
    git! 'commit', '-q', '-m', message
  end

  def git!(*args)
    system 'git', *args, exception: true, out: File::NULL, err: File::NULL
  end

  def with_env(env, &block)
    saved = env.to_h {|key, _| [key, ENV[key]]}
    env.each {|key, value| ENV[key] = value}
    block.call
  ensure
    saved.each {|key, value| ENV[key] = value}
  end

end# GitRepo
