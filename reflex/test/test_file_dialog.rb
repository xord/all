require_relative 'helper'


class TestFileDialog < Test::Unit::TestCase

  def dialog(*args, &block)
    Reflex::FileDialog.new(*args, &block)
  end

  def event(action, paths)
    Reflex::FileEvent.new action, paths
  end

  def test_initialize()
    assert_nil            dialog                            .owner
    assert_equal '',      dialog                            .title
    assert_equal 'hoge',  dialog(      title:  'hoge')      .title
    assert_equal 'hoge',  dialog      {title   'hoge'}      .title
    assert_equal 'hoge',  dialog {self.title = 'hoge'}      .title
    assert_equal [],      dialog                            .extensions
    assert_equal ['png'], dialog(      extensions:  ['png']).extensions
    assert_equal ['png'], dialog      {extensions   ['png']}.extensions
    assert_equal ['png'], dialog {self.extensions = ['png']}.extensions
  end

  def test_extensions()
    dialog.tap do |d|
      d.extensions = %w[png jpg]
      assert_equal   %w[png jpg], d.extensions
      d.extensions = ['txt']
      assert_equal   ['txt'],     d.extensions
    end

    assert_equal %w[png],    dialog(extensions: 'png')      .extensions
    assert_equal %w[png],    dialog(extensions: ['png'])    .extensions
    assert_equal %w[png],    dialog(extensions: [:png])     .extensions
    assert_equal %w[jpg],    dialog(extensions: ['.jpg'])   .extensions
    assert_equal %w[gif],    dialog(extensions: ['..gif'])  .extensions
    assert_equal %w[tar.gz], dialog(extensions: ['.tar.gz']).extensions

    assert_raise(ArgumentError) {dialog.extensions = ['']}
    assert_raise(ArgumentError) {dialog.extensions = ['.']}
    assert_raise(ArgumentError) {dialog.extensions = ['png', '']}
    assert_raise(ArgumentError) {dialog.extensions = ['*.png']}
    assert_raise(ArgumentError) {dialog.extensions = ['p?g']}
    assert_raise(ArgumentError) {dialog.extensions = ['png;jpg']}
    assert_raise(ArgumentError) {dialog.extensions = ['a/b']}
    assert_raise(ArgumentError) {dialog.extensions = [/png/]}
    assert_raise(ArgumentError) {dialog.extensions = [1]}
  end

  def test_on_file_open()
    d, paths = dialog, nil
    d.on(:file) {|e| paths = e.paths}
    d.on_file event(Reflex::FileEvent::OPEN, ['/a', '/b'])
    assert_equal ['/a', '/b'], paths
  end

  def test_on_file_save()
    d, got = dialog, nil
    d.on(:file) {|e| got = [e.action, e.path]}
    d.on_file event(Reflex::FileEvent::SAVE, ['/a'])
    assert_equal [:save, '/a'], got
  end

  def test_on_cancel()
    d, called = dialog, false
    d.on(:cancel) {|e| called = true}
    d.on_cancel event(Reflex::FileEvent::ACTION_NONE, [])
    assert_true called
  end

end# TestFileDialog
