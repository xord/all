require_relative 'helper'


class TestEditable < Test::Unit::TestCase

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

    assert_equal pj,  o.project
    assert_equal pj, pj.project
  end

  def test_parent()
    child = obj
    assert_nil child.parent

    parent = obj
    child.set_parent parent
    assert_equal parent, child.parent

    child.set_parent nil
    assert_nil child.parent
  end

  def test_modified?()
    o = obj child: obj
    assert_true [o, o.child].all?(&:modified?)

    o.save proj
    assert_true [o, o.child].none?(&:modified?)

    o.child.modified!
    assert_true [o, o.child].all?(&:modified?)
  end

  def test_modified!()
    parent, child = obj, obj
    child.set_parent parent

    logger = []
    parent.modified(observe_all: false) {logger << :parent_non_all}
    parent.modified(observe_all: true)  {logger << :parent_all}
    child .modified                     {logger << :child}

    child.modified!
    assert_equal [:child, :parent_all],          logger

    logger = []
    parent.modified!
    assert_equal [:parent_non_all, :parent_all], logger
  end

  def test_modified_count()
    o = obj
    assert_equal 1, o.modified_count

    o.modified!
    assert_equal 2, o.modified_count

    o.modified!
    o.modified!
    assert_equal 4, o.modified_count

    o.save proj
    assert_equal 0, o.modified_count

    parent = obj child: o
    assert_equal [1, 0], [parent.modified_count, o.modified_count]

    o.modified!
    assert_equal [2, 1], [parent.modified_count, o.modified_count]

    o.modified!
    o.modified!
    assert_equal [4, 3], [parent.modified_count, o.modified_count]

    parent.save proj
    assert_equal [0, 0], [parent.modified_count, o.modified_count]
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
