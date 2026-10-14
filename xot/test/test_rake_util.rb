require_relative 'helper'
require 'xot/rake'


class TestRakeUtil < Test::Unit::TestCase

  include Rake::DSL
  include Xot::Rake
  include GitRepo

  ChangeLog = Xot::ChangeLog

  def test_install_hooks()
    repo do
      install_hooks
      assert File.file?(      '.git/hooks/pre-commit')
      assert File.executable?('.git/hooks/pre-commit') unless win32?

      log = ChangeLog.new
      log.add '0.2.0', ['Add a'], date: Time.new(2026, 10, 12)
      git! 'add', 'ChangeLog.md'
      git! 'commit', '-q', '-m', 'Update ChangeLog'
      assert_equal '0.2.0', File.read('VERSION')
      assert_equal '0.2.0', IO.popen(%w[git show HEAD:VERSION], &:read)
      assert_empty IO.popen(%w[git status --porcelain], &:read)

      log.add '1', ['Add c'], date: Time.new(2026, 10, 12)
      git! 'add', 'ChangeLog.md'
      git! 'commit', '-q', '-m', 'Update ChangeLog'
      assert_equal '1', File.read('VERSION')

      log.add '0.3.0', ['Add b'], date: Time.new(2026, 10, 13)
      File.write 'VERSION', '9.9.9'
      git! 'add', 'ChangeLog.md'
      assert !system('git', 'commit', '-q', '-m', 'Update ChangeLog', out: File::NULL, err: File::NULL)
      assert_equal '9.9.9', File.read('VERSION')
    end
  end

  def test_version_changes()
    repo do
      assert_empty version_changes

      commit "Add a\n\nwith the body", 'a.rb' => ''
      commit 'Fix b',                  'sub/b.rb' => ''
      assert_equal ['Add a', 'Fix b'], version_changes
      assert_equal ['Fix b'],          version_changes('sub')

      commit 'Bump the version', 'VERSION' => '0.2.9'
      assert_empty version_changes

      # a branch merged, by the merge commit only, the line after 'Merge
      # branch ...' of which tells the changes of the branch
      git! 'checkout', '-q', '-b', 'topic'
      commit 'Add c', 'c.rb' => ''
      commit 'Add d', 'sub/d.rb' => ''
      git! 'checkout', '-q', '-'
      commit 'Fix e', 'e.rb' => ''
      git! 'merge', '-q', '--no-ff',
        '-m', "Merge branch 'topic'\n\nAdd c and d\n\nwith the body",
        'topic'
      assert_equal ['Fix e', 'Add c and d'], version_changes
      assert_equal ['Fix b', 'Add c and d'], version_changes('sub') # with no VERSION

      # the title of one with nothing after 'Merge branch ...', or of another
      git! 'checkout', '-q', '-b', 'topic2'
      commit 'Add f', 'f.rb' => ''
      git! 'checkout', '-q', '-'
      git! 'merge', '-q', '--no-ff', '-m', "Merge branch 'topic2'", 'topic2'
      git! 'checkout', '-q', '-b', 'topic3'
      commit 'Add g', 'g.rb' => ''
      git! 'checkout', '-q', '-'
      git! 'merge', '-q', '--no-ff', '-m', "Add g\n\nwith the body", 'topic3'
      assert_equal ["Merge branch 'topic2'", 'Add g'], version_changes.last(2)
    end
  end

  def test_next_version()
    repo do
      # the third number, of three numbers
      {
        '0.1.0'   => '0.1.1',
        '0.2.9'   => '0.2.10',
        '1.2'     => '1.2.1',
        '1'       => '1.0.1',
        '1.2.3.4' => '1.2.4'
      }.each do |version, next_|
        File.write 'VERSION', version
        assert_equal next_, next_version, version
      end
    end
  end

  def test_tag_versions()
    repo do
      commit 'Add a', 'a.rb' => ''
      ChangeLog.new.add '0.1.1', ['Add a'], date: Time.new(2026, 10, 12)
      commit 'Version 0.1.1', 'VERSION' => '0.1.1'
      commit 'Add b', 'b.rb' => ''

      verbose(false) {tag_versions}
      assert_equal %w[v0.1.0 v0.1.1], IO.popen(%w[git tag], &:read).lines(chomp: true)
      assert_equal(
        "- Add a\n",
        IO.popen(%w[git tag -l --format=%(contents) v0.1.1], &:read).sub(/\n+\z/, "\n"))
      assert_equal(
        IO.popen(%w[git rev-parse HEAD~1], &:read),
        IO.popen(%w[git rev-list -n 1 v0.1.1], &:read))

      # the versions back to the one tagged already, which is not tagged again
      commit 'Version 0.1.2', 'VERSION' => '0.1.2'
      verbose(false) {tag_versions}
      assert_equal(
        %w[v0.1.0 v0.1.1 v0.1.2],
        IO.popen(%w[git tag], &:read).lines(chomp: true))
    end
  end

end# TestRakeUtil
