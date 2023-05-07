require_relative 'helper'


class Temp < Rucy::Tester::Sub

  def name()
    "Temp::name"
  end

  def name_overridable()
    "Temp::name_overridable"
  end

end# Temp


class TestClass < Test::Unit::TestCase

  include Rucy::Tester

  def base(*args)
    Base.new(*args)
  end

  def sub(*args)
    Sub.new(*args)
  end

  def temp(*args)
    Temp.new(*args)
  end

  def base_raw(*args)
    Base.new_raw(*args)
  end

  def sub_raw(*args)
    Sub.new_raw(*args)
  end

  def last_log(pattern = nil)
    logs = Rucy::Tester.all_logs
    logs.select! {|o| o =~ pattern} if pattern
    logs.last
  end

  def test_is_kind_of_base()
    assert_kind_of Base, base
    assert_kind_of Base, base_raw

    assert_kind_of Base, sub
    assert_kind_of Base, sub_raw
    assert_kind_of Sub,  sub
    assert_kind_of Sub,  sub_raw

    assert_kind_of Base, temp
    assert_kind_of Sub,  temp
    assert_kind_of Temp, temp

    assert_not base     .kind_of?(Sub)
    assert_not base_raw .kind_of?(Sub)
    assert_not base     .kind_of?(Temp)
    assert_not base_raw .kind_of?(Temp)

    assert_not sub    .kind_of?(Temp)
    assert_not sub_raw.kind_of?(Temp)
  end

  def test_name()
    assert_equal "Base::name", base    .name
    assert_equal "Base::name", base_raw.name
    assert_equal "Sub::name",  sub     .name
    assert_equal "Sub::name",  sub_raw .name
    assert_equal "Temp::name", temp    .name
  end

  def test_name_overridable()
    assert_equal "Base::name_overridable", base    .name_overridable
    assert_equal "Base::name_overridable", base_raw.name_overridable
    assert_equal "Sub::name_overridable",  sub     .name_overridable
    assert_equal "Sub::name_overridable",  sub_raw .name_overridable
    assert_equal "Temp::name_overridable", temp    .name_overridable
  end

  def test_call_name()
    assert_equal "Base::name", base    .call_name
    assert_equal "Base::name", base_raw.call_name
    assert_equal "Sub::name",  sub     .call_name
    assert_equal "Sub::name",  sub_raw .call_name
    assert_equal "Sub::name",  temp    .call_name# "Sub" instead of "Temp"!
  end

  def test_call_name_overridable()
    assert_equal "Base::name_overridable", base    .call_name_overridable
    assert_equal "Base::name_overridable", base_raw.call_name_overridable
    assert_equal "Sub::name_overridable",  sub     .call_name_overridable
    assert_equal "Sub::name_overridable",  sub_raw .call_name_overridable
    assert_equal "Temp::name_overridable", temp    .call_name_overridable
  end

  def test_gc()
    def simple_objs(name, n = 10) ([nil] * n).map {SimpleObj.new name} end
    def gc() GC.start end
    rt = Rucy::Tester

    gc
    rt.clear_logs

    objs = simple_objs 1
    assert_equal 'SimpleObj(1)', last_log(/1/)
    gc
    assert_equal 'SimpleObj(1)', last_log(/1/)
    objs = nil
    gc
    assert_equal '~SimpleObj(1)', last_log(/1/)

    gc
    rt.clear_logs

    objs = simple_objs 2
    assert_equal 'SimpleObj(2)', last_log(/2/)
    SimpleObj.set_refs objs
    gc
    assert_equal 'SimpleObj(2)', last_log(/2/)
    objs = nil
    gc
    assert_equal 'SimpleObj(2)', last_log(/2/)
    SimpleObj.clear_refs
    gc
    assert_equal '~SimpleObj(2)', last_log(/2/)
  end

end# TestClass
