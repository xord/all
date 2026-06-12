require 'json'
require 'reflex/view'
require 'reflex-webview/ext'


module Reflex


  class WebView

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

  end# WebView


end# Reflex
