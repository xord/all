require_relative 'helper'


class TestEditable < Test::Unit::TestCase

  include HasContext

  def test_initialize()
    assert_true  obj          .modified?
    assert_false obj(load: {}).modified?
  end

  def test_save()
    o = obj name: :test
    assert_true                               o.modified?
    assert_equal ({child: nil, name: :test}), o.save(proj)
    assert_false                              o.modified?
  end

  def test_project()
    pj, o = proj, obj
    o.set_parent pj

    assert_equal_state pj,  o.project
    assert_equal_state pj, pj.project
  end

  def test_parent()
    child = obj
    assert_nil child.parent

    parent = obj
    child.set_parent parent
    assert_equal_state parent, child.parent

    child.set_parent nil
    assert_nil child.parent
  end

  def test_modified?()
    o = obj child: obj
    assert_true [o, o.child].all?(&:modified?)

    o.save proj
    assert_true [o, o.child].none?(&:modified?)

    o.child.modified! :changed
    assert_true [o, o.child].all?(&:modified?)
  end

  def test_modified_with_observe_all()
    parent, child = obj, obj
    child.set_parent parent

    logger = []
    parent.modified(observe_all: false) {logger << :parent_non_all}
    parent.modified(observe_all: true)  {logger << :parent_all}
    child .modified                     {logger << :child}

    child.modified! :changed
    assert_equal [:child, :parent_all],          logger

    logger = []
    parent.modified! :changed
    assert_equal [:parent_non_all, :parent_all], logger
  end

  def test_modified_with_type()
    o = obj
    notype = type1 = type2 = all_with_type = all_without_type = nil
    o.modified                            {|type:, **| notype           = type}
    o.modified(:type1)                    {|type:, **|   type1          = type}
    o.modified(:type2)                    {|type:, **|   type2          = type}
    o.modified(:dummy, observe_all: true) {|type:, **| all_with_type    = type}
    o.modified(        observe_all: true) {|type:, **| all_without_type = type}

    o.modified! :type1
    assert_equal(
      [ :type1, :type1,   nil,           nil,            :type1],
      [notype,   type1, type2, all_with_type, all_without_type])

    notype = type1 = type2 = all_with_type = all_without_type = nil
    o.modified! :type2
    assert_equal(
      [ :type2,  nil, :type2,           nil,            :type2],
      [notype, type1,  type2, all_with_type, all_without_type])

    notype = type1 = type2 = all_with_type = all_without_type = nil
    o.modified! :type9
    assert_equal(
      [ :type9,  nil,   nil,           nil,            :type9],
      [notype, type1, type2, all_with_type, all_without_type])
  end

  def test_modified_with_key()
    o = obj
    event_params = nil
    o.modified(observer_id: :hoge) {|**params| event_params = params}
    o.modified! :changed, key1: 1, key2: 2

    assert_equal(
      {type: :changed, origin: o, observer_id: :hoge, key1: 1, key2: 2},
      event_params)

    event_params = nil
    o.remove_modified_observer :hoge
    o.modified! :changed, key1: 1, key2: 2
    assert_nil event_params
  end

  def test_editable_writer()
    c = Class.new do
      extend  Reight::Editable::Accessor
      include Reight::Editable
      editable_writer :value
      attr_reader     :value
    end

    o          = c.new
    event_type = nil
    o.modified {|type:, **| event_type = type}

    assert_nil                   o.value
    assert_nil                   event_type

    assert_equal 1,              (o.value = 1)
    assert_equal 1,              o.value
    assert_equal :value_changed, event_type

    event_type = nil
    assert_equal 1,              (o.value = 1)
    assert_equal 1,              o.value
    assert_nil                   event_type

    assert_equal 2,              (o.value = 2)
    assert_equal 2,              o.value
    assert_equal :value_changed, event_type
  end

  def test_editable_writer_with_block()
    c = Class.new do
      extend  Reight::Editable::Accessor
      include Reight::Editable
      editable_writer(:value) {@value = _1 * 2}
      attr_reader     :value
    end

    o          = c.new
    event_type = nil
    o.modified {|type:, **| event_type = type}

    assert_nil                   o.value
    assert_nil                   event_type

    assert_equal 1,              (o.value = 1)
    assert_equal 2,              o.value
    assert_equal :value_changed, event_type

    event_type = nil
    assert_equal 1,              (o.value = 1)
    assert_equal 2,              o.value
    assert_nil                   event_type

    assert_equal 2,              (o.value = 2)
    assert_equal 4,              o.value
    assert_equal :value_changed, event_type
  end

  def test_editable_writer_filter()
    c = Class.new do
      extend  Reight::Editable::Accessor
      include Reight::Editable
      editable_writer :value, filter: -> x {x * 2}
      attr_reader     :value
    end

    o          = c.new
    event_type = nil
    o.modified {|type:, **| event_type = type}

    assert_nil                   o.value
    assert_nil                   event_type

    assert_equal 1,              (o.value = 1)
    assert_equal 2,              o.value
    assert_equal :value_changed, event_type

    event_type = nil
    assert_equal 1,              (o.value = 1)
    assert_equal 2,              o.value
    assert_nil                   event_type

    assert_equal 2,              (o.value = 2)
    assert_equal 4,              o.value
    assert_equal :value_changed, event_type
  end

  private

  class Obj
    include R8::Editable
    def initialize(child: nil, load: nil, **attrs)
      super(load: load)
      @child, @attrs = child, attrs
      @child&.set_parent self
    end
    attr_reader :child, :attrs
    def save(proj) = super.merge(child: @child&.save(proj), **@attrs)
  end

  def obj(...)           = Obj.new(...)

  def proj(dir = '/tmp') = R8::Project.new dir

end# TestEditable
