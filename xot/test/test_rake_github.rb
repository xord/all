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

end# TestRakeGitHub
