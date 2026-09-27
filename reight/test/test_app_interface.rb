require_relative 'helper'


class TestAppInterface < Test::Unit::TestCase

  include HasContext

  def interface(&block)
    R8::AppInterface.new(nil, nil).tap do |interface|
      interface.layout_popup(:test, &block) if block
    end
  end

  def button(label = 1)
    R8::Button.new label: label
  end

  def test_popup_shows_every_widget_its_block_puts()
    a, b = button(1), button(2)
    i    = interface {[a, b].each {put _1, w: 10, h: 10}}

    i.popup :test
    assert_false a.sprite.hidden?
    assert_false b.sprite.hidden?
  end

  def test_popup_leaves_other_popups_hidden()
    a, b = button(1), button(2)
    i    = R8::AppInterface.new nil, nil
    i.layout_popup(:one) {put a, w: 10, h: 10}
    i.layout_popup(:two) {put b, w: 10, h: 10}

    i.popup :one
    assert_false a.sprite.hidden?
    assert_true  b.sprite.hidden?
  end

  def test_popup_with_unknown_name_shows_nothing()
    a = button
    i = interface {put a, w: 10, h: 10}

    i.popup :unknown
    assert_true a.sprite.hidden?
  end

  def test_close_popup_hides_widgets()
    a = button
    i = interface {put a, w: 10, h: 10}

    i.popup :test
    i.close_popup
    assert_true a.sprite.hidden?
  end

  def test_reopening_popup_shows_widgets_again()
    a = button
    i = interface {put a, w: 10, h: 10}

    i.popup :test
    i.close_popup
    i.popup :test
    assert_false a.sprite.hidden?, 'popup must be visible on second open'
  end

  def test_close_popup_is_idempotent()
    a = button
    i = interface {put a, w: 10, h: 10}

    i.popup :test
    i.close_popup
    i.close_popup
    i.popup :test
    assert_false a.sprite.hidden?
  end

  def test_menu_registers_itself_and_its_items_by_name()
    i = interface
    i.menu(:foo_menu) {item :delete_foo, 'Delete'}

    del = i.delete_foo
    assert_kind_of R8::Menu,     i.foo_menu
    assert_kind_of R8::MenuItem, del
    assert_equal   'Delete',     del.label
    assert_equal   [del],        i.foo_menu.items
    assert_same    i.foo_menu,   i.menu(:foo_menu)
  end

  def test_asset_table_fires_open_menu_on_right_press_over_an_asset()
    asset = Struct.new(:id) do
      def hit?(x, y) = x < 50
    end.new 1
    table = R8::AssetTable.new 96, 96, 96, 96
    table.assets = [asset]
    fired = []
    table.open_menu {|x, y, a| fired << [x, y, a]}
    table.__send__ :mouse_pressed, 60, 2, :right   # empty space
    table.__send__ :mouse_pressed, 10, 2, :left    # over the asset
    table.__send__ :mouse_pressed, 10, 2, :right   # over the asset
    assert_equal [[10, 2, asset]], fired
  end

  def test_menu_item_fires_clicked_and_pulls_enabled()
    item  = R8::MenuItem.new label: 'Do'
    fired = 0
    item.clicked  {fired += 1}
    item.getInternal__.on_click Reflex::UpdateEvent.new(0, 0)
    assert_equal 1, fired

    assert_true item.enabled?
    on = false
    item.enabled? {on}
    assert_false item.enabled?
    on = true
    assert_true  item.enabled?
  end

  def test_widget_creates_once_and_defines_a_reader()
    i     = interface
    calls = 0
    made  = i.widget(:foo, -> {calls += 1; button})
    assert_equal made, i.widget(:foo)
    assert_equal made, i.foo
    assert_equal 1,    calls
  end

  def test_widget_rejects_creating_the_same_name_twice()
    i = interface
    i.widget(:foo, -> {button})
    assert_raise(RuntimeError) {i.widget(:foo, -> {button})}
  end

  def test_widget_tolerates_redeclaration_after_compose()
    c    = R8::ViewController.new nil
    made = c.widget(:foo, -> {button})
    c.compose
    assert_same made, c.widget(:foo, -> {button})
  end

  def test_widget_rejects_names_conflicting_with_methods()
    i = interface
    assert_raise(ArgumentError) {i.widget(:widget, -> {button})}
  end

  def test_widget_calls_delegate_method_for_symbol_factory()
    i = interface
    b = button
    i.define_singleton_method(:new_foo) {b}
    assert_equal b, i.widget(:foo, :new_foo)
    assert_equal b, i.widget(:foo)
  end

  def test_widget_raises_before_creation()
    assert_raise(RuntimeError) {interface.widget :unknown}
  end

end# TestAppInterface
