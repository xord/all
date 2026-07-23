require_relative 'helper'


class TestMenu < Test::Unit::TestCase

  def menu(*args, &block)
    Reflex::Menu.new(*args, &block)
  end

  def test_initialize()
    assert_equal '',     menu.label
    assert_equal 'File', menu(:File).label
  end

  def test_add_child()
    menu.tap do |m|
      m.add menu(:A)
      m.add menu(:B)
      m.add menu(:C), index: 1
      assert_equal 3,         m.size
      assert_equal %w[A C B], m.map(&:label)
    end

    menu.tap do |m|
      m.add menu(:A)
      m.add menu(:B), index: 0
      m.add menu(:C), index: m.size
      assert_equal %w[B A C], m.map(&:label)
    end

    menu.tap do |m|
      m.add menu(:A)
      m.add menu(:B), index: 99
      m.add menu(:C), index: -1
      m.add menu(:D), index: nil
      assert_equal %w[A B C D], m.map(&:label)
    end
  end

  def test_add_twice_to_same_parent()
    m = menu
    c = m.add menu
    m.add c
    assert_equal 1, m.size
  end

  def test_add_child_having_other_parent_raises()
    a, b = menu, menu
    c    = a.add menu
    assert_raise(ArgumentError, Reflex::ReflexError) {b.add c}
  end

  def test_add_nil_raises()
    assert_raise(TypeError, ArgumentError) {menu.add nil}
  end

  def test_remove()
    m = menu
    a = m.add menu(:A)
    m.add menu(:B)
    m.remove a
    assert_equal %w[B], m.map(&:label)
  end

  def test_clear_children()
    m = menu
    m.add menu(:A)
    m.clear_children
    assert_true m.empty?
  end

  def test_find_children()
    root = menu
    root.add(menu(:A)).name = :x
    root.add(menu(:B)).name = :x
    root.add(menu(:C)).name = :y
    assert_equal 2, root.find_children(:x).size
  end

  def test_find_children_recursive()
    root = menu
    file = root.add menu(:File)
    file.add(menu :Open).name = :x
    assert_equal 1, root.find_children(:x)       .size
    assert_equal 0, root.find_children(:x, false).size
  end

  def test_label()
    m       = menu
    m.label = :Open
    assert_equal 'Open', m.label
  end

  def test_label_changes_separator()
    m       = menu :File
    assert_false m.separator?
    m.label = '-'
    assert_true  m.separator?
    m.label = :Edit
    assert_false m.separator?
  end

  def test_enable_and_disable()
    m = menu
    assert_true  m.enabled?
    m.enable false
    assert_false m.enabled?
    m.enable
    assert_true  m.enabled?
    m.disable
    assert_false m.enabled?
  end

  def test_check_and_uncheck()
    m = menu
    assert_false m.checked?
    m.check true
    assert_true  m.checked?
    m.uncheck
    assert_false m.checked?
    m.check
    assert_true  m.checked?
  end

  def test_shortcut()
    m = menu
    m.shortcut_key = :s
    assert_equal 's', m.shortcut_key
    assert_equal [],  m.shortcut_modifiers

    m.shortcut = [:c, :command]
    assert_equal 'c',         m.shortcut_key
    assert_equal [:command],  m.shortcut_modifiers
  end

  def test_shortcut_key_keeps_modifiers()
    m = menu
    m.shortcut = [:c, :command, :shift]
    assert_equal  'c',                   m.shortcut_key
    assert_equal %i[command shift].sort, m.shortcut_modifiers.sort
    m.shortcut_key = :v
    assert_equal     'v',                m.shortcut_key
    assert_equal %i[command shift].sort, m.shortcut_modifiers.sort
  end

  def test_image()
    m, img  = menu, Reflex::Image.new(8, 8)
    assert_nil        m.image
    m.image = img
    assert_equal img, m.image
    m.image = nil
    assert_nil        m.image

    assert_raise(TypeError) {m.image = 1}
  end

  def test_separator()
    assert_false menu(:File).separator?
    assert_true  menu('-').separator?
    assert_true  menu('---').separator?
    assert_false menu('').separator?
  end

  def test_parent()
    m = menu
    c = m.add menu
    assert_equal m, c.parent
    assert_nil      m.parent
    m.remove c
    assert_nil      c.parent
  end

  def test_children()
    m = menu
    c = m.add menu
    assert_equal [c], m.children
    assert_equal  c,  m.first
  end

  def test_each_without_block()
    m = menu
    m.add menu(:A)
    assert_kind_of Enumerator, m.each
    assert_equal %w[A], m.each.map(&:label)
  end

  def test_nested()
    root = menu
    file = root.add menu(:File)
    file.add menu(:Open)
    assert_equal 'Open', root.first.first.label
  end

  def test_event_hooks()
    m     = menu
    fired = []
    %i[click show hide open_submenu close_submenu].each {|ev| m.on(ev) {|e| fired << ev}}
    e     = Reflex::UpdateEvent.new 0, 0
    m.on_click e
    m.on_show e
    m.on_hide e
    m.on_open_submenu e
    m.on_close_submenu e
    assert_equal %i[click show hide open_submenu close_submenu], fired
  end

end# TestMenu
