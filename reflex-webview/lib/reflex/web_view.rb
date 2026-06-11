require 'reflex/view'
require 'reflex-webview/ext'


module Reflex


  class WebView

    # Navigates to +url+. Equivalent to #load.
    def url=(url)
      load url.to_s
      url
    end

  end# WebView


end# Reflex
