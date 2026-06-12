require 'reflex/view'
require 'reflex-webview/ext'


module Reflex


  class WebView

    # Navigates to +url+. Equivalent to #load.
    def url=(url)
      load url.to_s
      url
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
