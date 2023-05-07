$RAYS_NOAUTOINIT = true

require_relative 'helper'


class TestRaysInit < Test::Unit::TestCase

  def test_init!()
    assert_raise(Rays::RaysError) {Rays.fin!}
    assert Rays.init!
    assert_raise(Rays::RaysError) {Rays.init!}
    assert Rays.fin!
  end

end# TestRaysInit
