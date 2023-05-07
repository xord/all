require_relative 'helper'


class TestException < Test::Unit::TestCase

  include Rucy::Tester

  def test_raise_ruby_exception()
    assert_raise(StandardError) {raise_ruby_exception}
  end

  def test_raise_in_eval()
    assert_raise(RuntimeError) {raise_in_eval}
  end

  def test_throw_std_exception()
    assert_raise(Rucy::NativeError) {throw_std_exception}
  end

  def test_throw_std_runtime_error()
    assert_raise(Rucy::NativeError) {throw_std_runtime_error}
  end

  def test_throw_custom_exception()
    assert_raise(Rucy::NativeError) {throw_custom_exception}
  end

  def test_throw_std_string()
    assert_raise(Rucy::NativeError) {throw_std_string}
  end

  def test_throw_cstring()
    assert_raise(Rucy::NativeError) {throw_cstring}
  end

end# TestException
