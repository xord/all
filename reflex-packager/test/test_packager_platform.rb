require_relative 'helper'


class TestPackagerPlatform < Test::Unit::TestCase

  RP = Reflex::Packager

  def test_methods_to_implement()
    platform = RP::Platform.new nil
    %i[generate build platform_name].each do |name|
      error = assert_raise(RuntimeError) {platform.send name}
      assert_include error.message, "must implement #{name}"
    end
  end

end# TestPackagerPlatform
