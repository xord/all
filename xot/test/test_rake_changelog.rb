require_relative 'helper'
require 'tmpdir'
require 'xot/rake/changelog'


class TestRakeChangeLog < Test::Unit::TestCase

  TEXT = <<~END
    # app ChangeLog


    ## [v1.2.3] - 2026-10-12

    - Add a "quoted" thing
    - Fix another


    ## [ v1.2 ] - 2026-10-01

    - First
  END

  def changelog(text = TEXT, &block)
    Dir.mktmpdir do |dir|
      path = File.join dir, 'ChangeLog.md'
      File.write path, text
      block.call Xot::ChangeLog.new(path)
    end
  end

  def test_add()
    changelog do |log|
      log.add '1.2.4', ['Add more', 'Fix it'], date: Time.new(2026, 10, 13)
      assert_equal <<~END, File.read(log.path)
        # app ChangeLog


        ## [v1.2.4] - 2026-10-13

        - Add more
        - Fix it


        ## [v1.2.3] - 2026-10-12

        - Add a "quoted" thing
        - Fix another


        ## [ v1.2 ] - 2026-10-01

        - First
      END
      assert_equal %w[1.2.4 1.2.3 1.2], log.versions
    end

    changelog "# app ChangeLog\n" do |log|
      log.add 'v0.1.0', ['First'], date: Time.new(2026, 10, 13)
      assert_equal(
        "# app ChangeLog\n\n\n## [v0.1.0] - 2026-10-13\n\n- First\n",
        File.read(log.path))
      assert_equal %w[0.1.0], log.versions
    end

    # before the section of a version, below one of none
    changelog "# app ChangeLog\n\n\n## Unreleased\n\n- Next\n\n\n## [v0.1.0] - 2026-10-01\n\n- First\n" do |log|
      log.add '0.1.1', ['Add a'], date: Time.new(2026, 10, 13)
      assert_equal(
        "# app ChangeLog\n\n\n## Unreleased\n\n- Next\n\n\n" +
        "## [v0.1.1] - 2026-10-13\n\n- Add a\n\n\n## [v0.1.0] - 2026-10-01\n\n- First\n",
        File.read(log.path))
    end
  end

  def test_sections()
    changelog do |log|
      assert_equal %w[1.2.3 1.2],                             log.versions
      assert_equal "- Add a \"quoted\" thing\n- Fix another", log.changes('1.2.3')
      assert_equal "- Add a \"quoted\" thing\n- Fix another", log.changes('v1.2.3')
      assert_equal '- First',                                 log.changes('1.2')
      assert_nil                                              log.changes('9.9')
    end
    changelog("# app ChangeLog\n") {|log| assert_empty log.versions}
  end

end# TestRakeChangeLog
