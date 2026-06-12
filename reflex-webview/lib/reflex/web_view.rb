require 'reflex/view'
require 'reflex-webview/ext'


module Reflex


  class WebView

    # Navigates to +url+. Equivalent to #load.
    def url=(url)
      load url.to_s
      url
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
