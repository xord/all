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

  def test_download_api()
    wv = web_view
    assert_respond_to wv, :download
    %i[on_download on_download_progress on_download_finish on_download_fail]
      .each {|name| assert_respond_to wv, name}
  end

  def test_download_object()
    d = Reflex::WebView::Download.new nil, 1, 'https://x/f.zip', 'f.zip', 1000
    assert_equal 'https://x/f.zip', d.url
    assert_equal 'f.zip', d.suggested_filename
    assert_equal 1000,    d.total_bytes
    assert_equal 0,       d.received_bytes
    assert_equal :downloading, d.state
    assert_in_delta 0.0,  d.fraction, 0.001
    d.update__ 500, 1000, :downloading, nil
    assert_in_delta 0.5,  d.fraction, 0.001
    d.path = '/tmp/out.zip'
    assert_equal '/tmp/out.zip', d.path
  end

  def test_download_event_wraps_download()
    d = Reflex::WebView::Download.new nil, 1, 'u', 'f', 0
    e = Reflex::WebView::DownloadEvent.new d
    assert_same d, e.download
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
      video_capture? video_capture=
    ].each {|name| assert_respond_to wv, name}
  end

  def test_video_capture_defaults_off_and_is_settable()
    wv = web_view
    assert_equal false, wv.video_capture?
    wv.video_capture = true
    assert_equal true,  wv.video_capture?
    wv.video_capture = false
    assert_equal false, wv.video_capture?
  end

  def test_session_state_api()
    wv = web_view
    assert_respond_to wv, :session_state
    assert_respond_to wv, :session_state=
    # the macOS backend serializes an (initially empty) session as a
    # base64 string; either a String or nil is acceptable here.
    state = wv.session_state
    assert(state.nil? || state.is_a?(String))
    # nil / empty / garbage are rejected loudly (there is no "clear")
    assert_raise(ArgumentError) {wv.session_state = nil}
    assert_raise(ArgumentError) {wv.session_state = ''}
    assert_raise(ArgumentError) {wv.session_state = 'not valid @@@'}
    # a round-tripped value restores without error
    assert_nothing_raised {wv.session_state = state} if state
  end

  def test_data_store_default_is_persistent_and_unnamed()
    ds = Reflex::WebView::DataStore.default
    assert_kind_of Reflex::WebView::DataStore, ds
    assert_equal true, ds.persistent?
    assert_nil ds.name
  end

  def test_data_store_new_is_ephemeral()
    ds = Reflex::WebView::DataStore.new
    assert_equal false, ds.persistent?
    assert_nil ds.name
    # each .new is a fresh, independent ephemeral store
    refute_same ds, Reflex::WebView::DataStore.new
  end

  def test_data_store_load_named()
    omit 'named data stores need macOS 14+' unless macos_14_or_later?
    ds = Reflex::WebView::DataStore.load 'test-profile'
    assert_equal true,           ds.persistent?
    assert_equal 'test-profile', ds.name
  end

  def test_data_store_cookies_api()
    ds = Reflex::WebView::DataStore.new
    assert_respond_to ds, :cookies
    assert_respond_to ds, :cookies=
    # a fresh ephemeral store has no cookies yet
    c = ds.cookies
    assert(c.nil? || c.is_a?(String))
    # restoring nil / empty / a round-tripped value is a no-op, not an error
    assert_nothing_raised do
      ds.cookies = nil
      ds.cookies = ''
      ds.cookies = c if c
    end
  end

  def test_data_store_clear_is_a_noop_smoke()
    assert_nothing_raised do
      Reflex::WebView::DataStore.new.clear
      Reflex::WebView::DataStore.default.clear
    end
  end

  def test_web_view_uses_default_data_store_by_default()
    wv = web_view
    assert_kind_of Reflex::WebView::DataStore, wv.data_store
    assert_equal true, wv.data_store.persistent?
  end

  def test_web_view_accepts_a_data_store_positionally()
    ds = Reflex::WebView::DataStore.new
    wv = Reflex::WebView.new ds
    assert_same ds, wv.data_store
    assert_equal false, wv.data_store.persistent?
  end

  def test_web_view_shares_a_data_store_between_views()
    a = Reflex::WebView.new Reflex::WebView::DataStore.new
    b = Reflex::WebView.new a.data_store
    assert_same a.data_store, b.data_store
  end

  def test_web_view_accepts_data_store_and_options_together()
    ds = Reflex::WebView::DataStore.new
    wv = Reflex::WebView.new ds, name: :web
    assert_same ds, wv.data_store
    assert_equal 'web', wv.name.to_s
  end

  def macos_14_or_later?()
    require 'rbconfig'
    ver = `sw_vers -productVersion 2>/dev/null`.to_i
    ver >= 14
  end

  def test_find_api()
    wv = web_view
    %i[find find_next find_previous].each {|m| assert_respond_to wv, m}
    # find! is the private raw binding
    assert_equal false, wv.respond_to?(:find!)
    assert wv.respond_to?(:find!, true)
    assert_nothing_raised do
      wv.find 'x'
      wv.find 'x', forward: false, case_sensitive: true, wrap: false
      wv.find_next
      wv.find_previous
      wv.find('y') {|found|}
    end
  end

  def test_find_next_without_prior_find_is_a_noop()
    assert_nothing_raised {web_view.find_next}
  end

  def test_load_accepts_headers()
    wv = web_view
    # load! is the private raw binding (url, headers-or-nil)
    assert wv.respond_to?(:load!, true)
    assert_nothing_raised do
      wv.load 'https://example.com'
      wv.load 'https://example.com', headers: {'X-Foo' => 'bar', 'X-Baz' => 1}
    end
  end

  def test_navigate_event_type()
    e = Reflex::WebView::NavigateEvent.new 'https://example.com'
    assert_equal :other, e.type
  end

  def test_scroll_api()
    wv = web_view
    assert_respond_to wv, :scroll_position
    assert_respond_to wv, :scroll_to
    pos = wv.scroll_position
    assert_kind_of Array, pos
    assert_equal 2, pos.size
    assert_equal [0.0, 0.0], pos
    assert_nothing_raised {wv.scroll_to 0, 100}
  end

  def test_audio_api()
    wv = web_view
    assert_respond_to wv, :playing_audio?
    assert_respond_to wv, :muted?
    assert_respond_to wv, :mute
    assert_equal false, wv.playing_audio?
    assert_nothing_raised do
      wv.mute
      wv.mute false
    end
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
