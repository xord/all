# -*- coding: utf-8 -*-


require_relative 'helper'


class TestShape < Test::Unit::TestCase

  def shape(*args, &block)
    Reflex::RectShape.new(*args, &block)
  end

  def test_density()
    s = shape
    assert_equal 0, s.density
    s.density = 1
    assert_equal 1, s.density
    s.density 2
    assert_equal 2, s.density
  end

  def test_friction()
    s = shape
    assert_equal 0, s.friction
    s.friction = 1
    assert_equal 1, s.friction
    s.friction 2
    assert_equal 2, s.friction
  end

  def test_restitution()
    s = shape
    assert_equal 0, s.restitution
    s.restitution = 1
    assert_equal 1, s.restitution
    s.restitution 2
    assert_equal 2, s.restitution
  end

  def test_sensor()
    s = shape
    assert_equal false, s.sensor?
    s.sensor = true
    assert_equal true, s.sensor?
    s.sensor false
    assert_equal false, s.sensor?
  end

  def test_category()
    s = shape
    assert_equal 0b1,    s.category_bits
    s.category_bits  =  0b1010
    assert_equal 0b1010, s.category_bits
    s.category_bits |=  0b100
    assert_equal 0b1110, s.category_bits
    s.category_bits &= ~0b10
    assert_equal 0b1100, s.category_bits
  end

  def test_collision()
    s = shape
    assert_equal 0xffff, s.collision_mask
    s.collision_mask  =  0b1010
    assert_equal 0b1010, s.collision_mask
    s.collision_mask |=  0b100
    assert_equal 0b1110, s.collision_mask
    s.collision_mask &= ~0b10
    assert_equal 0b1100, s.collision_mask
  end

end# TestShape
