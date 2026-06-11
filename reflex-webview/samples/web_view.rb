%w[xot rucy rays reflex reflex-webview]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'
require 'reflex-webview'

include Reflex


HTML = <<~END
  <html><head><style>
    body { margin: 0; font-family: -apple-system, sans-serif;
           background: linear-gradient(135deg, #1e3c72, #2a5298); color: #fff }
    h1   { padding: 20px }
    #box { width: 120px; height: 120px; margin: 20px; border-radius: 16px;
           background: #ff9800; animation: spin 2s linear infinite }
    @keyframes spin { to { transform: rotate(360deg) } }
  </style></head><body>
    <h1>Reflex::WebView</h1>
    <div id="box"></div>
    <p style="padding:0 20px">Rendered off-screen by WKWebView,
       captured into a texture every frame.</p>
  </body></html>
END


win = Window.new do
  add web = WebView.new {set name: :web, frame: [0, 0, 480, 360]}
  web.load_html HTML

  set title: 'WebView Sample', frame: [100, 100, 480, 360]
end


Reflex.start do
  win.show
end
