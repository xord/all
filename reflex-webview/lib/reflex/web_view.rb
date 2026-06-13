require 'json'
require 'reflex/view'
require 'reflex-webview/ext'


module Reflex


  class WebView

    # One entry in the back/forward history. Navigable via #go.
    class HistoryItem

      attr_reader :url, :title

      def initialize(web_view, offset, url, title)
        @web_view, @offset, @url, @title = web_view, offset, url, title
      end

      # Offset from the current entry (negative = back, positive
      # = forward, 0 = current).
      attr_reader :offset

      # Navigates the WebView to this history entry.
      def go()
        @web_view.go_to @offset
      end

    end# HistoryItem

    class MessageEvent

      # The message posted from page JavaScript, parsed from JSON.
      # The page is free to send anything: treat as untrusted input.
      def data()
        @data ||= JSON.parse raw_data
      end

    end# MessageEvent

    # Navigates to +url+. Equivalent to #load.
    def url=(url)
      load url.to_s
      url
    end

    # Reloads the current page. Pass true to bypass the cache and
    # revalidate every resource.
    def reload(ignore_cache = false)
      reload! ignore_cache
      self
    end

    # Sends a message to page JavaScript, delivered to the page's
    # __REFLEX__.onmessage handler. +data+ is serialized to JSON, so it
    # must be JSON-encodable.
    def post_message(data)
      post_message! JSON.generate(data)
      self
    end

    # The back history as HistoryItem objects, oldest first.
    def back_list()
      raw = back_list!
      n   = raw.size
      raw.each_with_index.map {|(url, title), i|
        HistoryItem.new self, i - n, url, title}
    end

    # The forward history as HistoryItem objects, nearest first.
    def forward_list()
      forward_list!.each_with_index.map {|(url, title), i|
        HistoryItem.new self, i + 1, url, title}
    end

    # The current history entry as a HistoryItem, or nil.
    def current_item()
      url, title = current_item!
      url && HistoryItem.new(self, 0, url, title)
    end

    alias eval_js! eval_js

    # Runs JavaScript in the page. With a block, the result is
    # delivered to it asynchronously (nil if the script failed or the
    # result is not expressible as JSON).
    def eval_js(script, &block)
      if block
        eval_js!(script) {|json| block.call(json && JSON.parse(json).first)}
      else
        eval_js! script
      end
      self
    end

    # Called when page JavaScript posts a message via
    # __REFLEX__.postMessage(data). Override in a subclass.
    def on_message(e)
    end

    # Called when the page's web content process crashes. The default
    # reloads the page; override (without calling super) to handle it
    # differently.
    def on_crash(e)
      reload
    end

    # Called for each page console.* call (e.level / e.message).
    # Override in a subclass.
    def on_console(e)
    end

    # Called when the page favicon URL changes (see #favicon).
    # Override in a subclass.
    def on_favicon_change(e)
    end

    # Called when the hovered link URL changes (see #hovered_url).
    # Override in a subclass.
    def on_hover(e)
    end

    # Called before each main-frame navigation. Call e.block to cancel
    # the navigation. Override in a subclass.
    def on_navigate(e)
    end

    # Called for window.open / target=_blank requests. The default
    # opens the URL in this view; a browser app overrides this to
    # create a new tab or window instead.
    def on_open(e)
      load e.url unless e.blocked?
    end

    # Called when a page starts loading. Override in a subclass.
    def on_load_start(e)
    end

    # Called when a page finishes loading. Override in a subclass.
    def on_load(e)
    end

    # Called when a page fails to load. Override in a subclass.
    def on_load_fail(e)
    end

    # Called when the page title changes. Override in a subclass.
    def on_title_change(e)
    end

    # Called when the page URL changes. Override in a subclass.
    def on_url_change(e)
    end

    # Called when the back/forward list changes, including via the
    # page's JS History API. Override in a subclass.
    def on_history_change(e)
    end

  end# WebView


end# Reflex
