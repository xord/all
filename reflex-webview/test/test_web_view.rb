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
    %i[load url url= load_html eval_js reload].each do |name|
      assert_respond_to wv, name
    end
  end

  def test_initial_url_is_empty()
    assert_equal '', web_view.url
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
