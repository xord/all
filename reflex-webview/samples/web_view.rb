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
           background: #ff9800; animation: spin 0.8s linear infinite }
    @keyframes spin { to { transform: rotate(360deg) } }
    #bar { width: 40px; height: 24px; background: #4caf50; border-radius: 6px;
           position: absolute; top: 30px; left: 0;
           animation: slide 1.4s ease-in-out infinite alternate }
    @keyframes slide { to { left: 380px } }
  </style></head><body>
    <div id="bar"></div>
    <h1>Reflex::WebView</h1>
    <div id="box"></div>
    <p style="padding:0 20px">raf: <span id="raf">0</span>
       &nbsp; tim: <span id="tim">0</span>
       &nbsp; vis: <span id="vis">?</span></p>
    <script>
      let r = 0, t = 0;
      (function loop(){ r++; document.getElementById('raf').textContent = r;
        requestAnimationFrame(loop); })();
      setInterval(function(){ t++;
        document.getElementById('tim').textContent = t;
        document.getElementById('vis').textContent = document.visibilityState;
      }, 100);
    </script>
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
