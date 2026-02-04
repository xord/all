require_relative 'helper'


class TestEditable < Test::Unit::TestCase

  def test_initialize()
    assert_true  obj          .modified?
    assert_false obj(load: {}).modified?
  end

  def test_save()
    o = obj name: :test
    assert_true                   o.modified?
    assert_equal ({name: :test}), o.save(proj)
    assert_false                  o.modified?
  end

  def test_project()
    pj = proj
    o  = obj
    o.set_parent pj.root

    assert_equal pj, o.project
  end

  def test_parent()
    parent, child = obj, obj
    assert_nil child.parent

    child.set_parent parent
    assert_equal parent, child.parent

    child.set_parent nil
    assert_nil child.parent
  end

  def test_modified?()
    pj = proj
    assert_true [pj, pj.root].all?(&:modified?)

    pj.save
    assert_true [pj, pj.root].none?(&:modified?)

    pj.root.modified!
    assert_true [pj, pj.root].all?(&:modified?)
  end

  def test_modified!()
    pj_modified_event = root_modified_event = false

    pj = proj
    pj     .modified {  pj_modified_event = true}
    pj.root.modified {root_modified_event = true}

    pj.root.modified!
    assert_true  pj     .modified?
    assert_true  pj.root.modified?
    assert_false   pj_modified_event
    assert_true  root_modified_event
  end

  private

  class Obj
    include R8::Editable
    attr_reader :attrs
    def initialize(load: nil, **attrs)
      super(load: load)
      @attrs = attrs
    end
    def save(proj) = super.merge @attrs
  end

  class Proj < R8::Project
    include R8::Editable
    def initialize(...)
      super()
      @root = Obj.new name: :root
      @root.set_parent self
    end
    attr_reader :root
    def save() = super(self).merge root: root.save(self)
  end

  def obj(...)           = Obj.new(...)

  def proj(dir = '/tmp') = Proj.new dir

end# TestEditable
