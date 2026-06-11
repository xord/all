require 'reflex/view'
require 'reflex-webview/ext'


module Reflex


  class WebView

    # Navigates to +url+. Equivalent to #load.
    def url=(url)
      load url.to_s
      url
    end

    # Called when a page finishes loading. Override in a subclass.
    def on_load(e)
    end

  end# WebView


end# Reflex
