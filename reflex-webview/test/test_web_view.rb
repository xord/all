require_relative 'helper'


class TestWebView < Test::Unit::TestCase

  def web_view(*args, &block)
    Reflex::WebView.new(*args, &block)
  end

  def test_is_a_view()
    assert_kind_of Reflex::View, web_view
  end

  def test_responds_to_api()
    wv = web_view
    %i[
      load url url= load_html eval_js reload
      go_back go_forward stop can_go_back? can_go_forward? loading? title
    ].each do |name|
      assert_respond_to wv, name
    end
  end

  def test_initial_url_is_empty()
    assert_equal '', web_view.url
  end

  def test_initial_title_is_empty()
    assert_equal '', web_view.title
  end

  def test_initial_navigation_state()
    wv = web_view
    assert_equal false, wv.can_go_back?
    assert_equal false, wv.can_go_forward?
    assert_equal false, wv.loading?
  end

  def test_responds_to_event_handlers()
    wv = web_view
    %i[
      on_load_start on_load on_load_fail on_title_change on_url_change
      on_crash on_message on_console on_favicon_change on_hover
      on_history_change
    ].each do |name|
      assert_respond_to wv, name
    end
  end

  def test_history_list_api()
    wv = web_view
    assert_respond_to wv, :back_list
    assert_respond_to wv, :forward_list
    assert_respond_to wv, :current_item
    assert_respond_to wv, :go_to
    assert_equal [], wv.back_list
    assert_equal [], wv.forward_list
    assert_nil wv.current_item
  end

  def test_history_item()
    item = Reflex::WebView::HistoryItem.new nil, -1, 'https://example.com', 'Example'
    assert_equal 'https://example.com', item.url
    assert_equal 'Example', item.title
    assert_equal(-1, item.offset)
  end

  def test_favicon_and_hovered_url_initially_nil()
    wv = web_view
    assert_nil wv.favicon
    assert_nil wv.hovered_url
  end

  def test_responds_to_post_message()
    assert_respond_to web_view, :post_message
  end

  def test_responds_to_find()
    assert_respond_to web_view, :find
  end

  def test_console_event()
    e = Reflex::WebView::ConsoleEvent.new 'warn', 'hello world'
    assert_kind_of Reflex::Event, e
    assert_equal 'warn',        e.level
    assert_equal 'hello world', e.message
  end

  def test_load_event()
    e = Reflex::WebView::LoadEvent.new 'https://example.com', 42, 'oops'
    assert_kind_of Reflex::Event, e
    assert_equal 'https://example.com', e.url
    assert_equal 42,     e.code
    assert_equal 'oops', e.description
  end

  def test_navigate_event()
    e = Reflex::WebView::NavigateEvent.new 'https://example.com'
    assert_kind_of Reflex::Event, e
    assert_equal 'https://example.com', e.url
    assert_equal false, e.blocked?
    e.block
    assert_equal true, e.blocked?
  end

  def test_responds_to_navigate_handlers()
    wv = web_view
    assert_respond_to wv, :on_navigate
    assert_respond_to wv, :on_open
  end

  def test_message_event()
    e = Reflex::WebView::MessageEvent.new '{"a": 1, "b": [true, null]}'
    assert_kind_of Reflex::Event, e
    assert_equal({'a' => 1, 'b' => [true, nil]}, e.data)
  end

  def test_message_event_with_scalar_data()
    assert_equal 42,    Reflex::WebView::MessageEvent.new('42').data
    assert_equal 'hi',  Reflex::WebView::MessageEvent.new('"hi"').data
    assert_nil          Reflex::WebView::MessageEvent.new('null').data
  end

  def test_responds_to_on_message()
    assert_respond_to web_view, :on_message
  end

  def test_eval_js_accepts_a_block()
    assert_nothing_raised do
      web_view.eval_js('1 + 2') {|result|}
    end
  end

  def test_to_image_is_nil_before_any_capture()
    assert_nil web_view.to_image
  end

  def test_responds_to_property_api()
    wv = web_view
    %i[
      progress user_agent user_agent= zoom zoom= inspectable? inspectable=
    ].each {|name| assert_respond_to wv, name}
  end

  def test_reload_is_public_and_takes_optional_force()
    wv = web_view
    assert_respond_to wv, :reload
    # reload! is the private raw binding
    assert_equal false, wv.respond_to?(:reload!)
    assert wv.respond_to?(:reload!, true)
  end

  def test_initial_property_values()
    wv = web_view
    assert_equal 0.0, wv.progress
    assert_equal 1.0, wv.zoom
    assert_equal false, wv.inspectable?
    assert_nil wv.user_agent
  end

  def test_zoom_is_settable()
    wv = web_view
    wv.zoom = 1.5
    assert_in_delta 1.5, wv.zoom, 0.001
  end

  def test_can_set_frame()
    wv = web_view
    wv.frame = [1, 2, 30, 40]
    assert_equal 30, wv.frame.w
    assert_equal 40, wv.frame.h
  end

  def test_load_requires_an_argument()
    assert_raise(ArgumentError) {web_view.load}
  end

  def test_load_html_requires_an_argument()
    assert_raise(ArgumentError) {web_view.load_html}
  end

  def test_eval_js_requires_an_argument()
    assert_raise(ArgumentError) {web_view.eval_js}
  end

end# TestWebView
