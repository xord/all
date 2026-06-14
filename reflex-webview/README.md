# Reflex WebView - An off-screen web browser view for Reflex

![License](https://img.shields.io/github/license/xord/reflex-webview)
![Build Status](https://github.com/xord/reflex-webview/actions/workflows/test.yml/badge.svg)
![Gem Version](https://badge.fury.io/rb/reflex-webview.svg)

## ⚠️  Notice

This repository is a read-only mirror of our monorepo.
We do not accept pull requests or direct contributions here.

### 🔄 Where to Contribute?

All development happens in our [xord/all](https://github.com/xord/all) monorepo, which contains all our main libraries.
If you'd like to contribute, please submit your changes there.

For more details, check out our [Contribution Guidelines](./CONTRIBUTING.md).

Thanks for your support! 🙌

## About

`reflex-webview` adds `Reflex::WebView`, a `Reflex::View` subclass that
renders web content off-screen and draws it into the Reflex scene every
frame, forwarding pointer, wheel, and keyboard events to the page.

Because the page is captured as a `Rays::Image` and drawn by Reflex
itself, web content can be freely composited with Reflex's own 2D/GL
drawing — transformed, used as a texture, mixed with shapes — which a
plain embedded webview cannot do. The trade-off is the off-screen capture
model and the workarounds it needs (see *Known limitations*).

The rendering backend depends on the platform:

- **macOS** — `WKWebView` rendered off-screen and captured into a texture.
- **Windows / Linux** — Chromium Embedded Framework (CEF). *(planned)*

## Quick start

```ruby
require 'reflex'
require 'reflex-webview'

Reflex.start do
  Reflex::Window.new do
    add web = Reflex::WebView.new {set name: :web, frame: [0, 0, 800, 600]}
    web.url = 'https://www.example.com/'
    web.focus
  end.show
end
```

A fuller example — an address bar with back / forward / reload buttons —
lives in [`examples/simple_browser.rb`](./examples/simple_browser.rb).

## Features

### Navigation & state
- `url=` / `url`, `load(url, headers: {...})`, `load_html(html)`
- `reload(ignore_cache = false)`, `stop`
- `go_back`, `go_forward`, `go_to(offset)`
- `can_go_back?`, `can_go_forward?`, `loading?`, `progress`, `title`
- Back/forward history list: `back_list`, `forward_list`, `current_item`
  (each a `HistoryItem` with `#go`); kept in sync with the JS History API.

### Input
Pointer, wheel and keyboard events are forwarded to the page
automatically — pointer and wheel reach it while the cursor is over the
view, and `focus` directs keyboard input to the page. Hover (`:hover`,
`mouseenter`/`mouseover`) works as well.

### JavaScript bridge
- `eval_js(script) {|result| ... }` — evaluate JS, optional result callback.
- `post_message(data)` — send JSON-serializable data to the page; it
  arrives at `window.__REFLEX__.onmessage`.
- The page calls `window.__REFLEX__.postMessage(data)` to send data back;
  handle it with `on_message(e)` (`e.data` is the parsed value).

### Properties
- `user_agent` / `user_agent=`
- `zoom` / `zoom=` (1.0 = 100%)
- `inspectable?` / `inspectable=` — attach Safari's Web Inspector (macOS 13.3+)
- `favicon`, `hovered_url`
- `video_capture?` / `video_capture=` — see *Hardware video* below
- `to_image` — a copy of the latest captured page image (`Rays::Image`),
  handy for headless screenshotting.

### Downloads
- `download(url)` — start a download programmatically.
- `on_download(e)` — `e.download` is a `Download`; set `e.download.path =`
  to choose the destination (defaults to a unique name in the current
  directory).
- `on_download_progress`, `on_download_finish`, `on_download_fail`;
  `Download#fraction`, `Download#cancel`.

### Data stores (cookies, incognito, profiles)

A `DataStore` is the cookies, local storage, and caches a WebView reads
and writes. Pass one to `WebView.new` to isolate or share browsing data;
the store is fixed for the life of the view.

```ruby
Reflex::WebView.new                                 # shared default store
Reflex::WebView.new(Reflex::WebView::DataStore.new) # incognito (ephemeral)
Reflex::WebView.new(Reflex::WebView::DataStore.load('work'))  # named profile

# share one store between views (e.g. tabs in the same profile)
tab2 = Reflex::WebView.new(tab1.data_store)
```

- `DataStore.default` — the shared, persistent default store.
- `DataStore.new` — a fresh ephemeral (incognito) store; nothing is
  written to disk and the data is gone once the store is released.
- `DataStore.load('name')` — a named persistent profile, kept separate
  from the default and from other names and persisted across runs (macOS
  14+).
- `store.persistent?`, `store.name`, `store.clear` (wipe all its data).
- `store.cookies` — all cookies as an opaque base64 string (or `nil`);
  `store.cookies = str` restores them (merging) into any store. Handy for
  persisting an ephemeral session, or alongside a view's `session_state`
  when hibernating a tab. `store.cookies = nil` clears all cookies
  (leaving local storage and caches; use `store.clear` to wipe
  everything).
- `web.data_store` — the store a view is using (pass it to another
  `WebView.new` to share).

### Session state (tab hibernation)
- `session_state` — the page session (back/forward history, scroll
  position and form field values) as an opaque base64 string, or `nil`.
- `session_state = str` — restore it into a (possibly fresh) WebView; the
  page reloads, then its history, scroll and form values are reapplied.

This is the primitive for a tab browser that suspends idle tabs: dump
`session_state`, destroy the WebView to free its renderer process, and
recreate + restore on demand. Cookies and local storage live in the
view's data store (see *Data stores* above) and persist independently;
dump `data_store.cookies` too if you need to carry them across an
ephemeral store.

### Find
- `find(text, forward: true, case_sensitive: false, wrap: true) {|found:| }`
  — search the page; the block (optional) is called with the keyword
  `found:` telling whether a match was located.
- `find_next {|found:| }` / `find_previous {|found:| }` — repeat the last
  search in either direction.

### Security
- `secure?` — whether the current page loaded entirely over a valid,
  secure connection (the "lock icon" state).
- `certificate` — the server `Certificate` (or `nil`): `#subject`,
  `#issuer`, `#not_before` / `#not_after` (Time), `#serial`,
  `#fingerprint` (SHA-256 hex).

### Scroll & audio
- `scroll_position` — the page's current `[x, y]` scroll offset.
- `scroll_to(x, y)` — scroll the page.
- `playing_audio?` — whether the page is currently playing audio.
- `muted?` / `mute(state = true)` — query / toggle the page's audio mute.

### Events (override on a subclass)
- Load: `on_load_start`, `on_load` (`LoadEvent`), `on_load_fail`
- `on_title_change`, `on_url_change`, `on_history_change`
- `on_navigate(e)` — `e.block` to cancel a navigation; `e.type` is the
  kind (`:link`, `:form`, `:back_forward`, `:reload`, `:form_resubmit`,
  `:other`)
- `on_open` — `window.open` / `target=_blank` (opens in-place by default)
- `on_crash` — renderer crash (auto-reloads)
- `on_console` (`ConsoleEvent`), `on_favicon_change`, `on_hover`
- `on_authenticate(e)` — HTTP auth; `e.use(user, password)` or
  `e.cancel` (default cancels). `e.host`, `e.port`, `e.realm`,
  `e.method` (`:basic`/`:digest`/`:ntlm`).
- `on_certificate_error(e)` — invalid certificate; `e.proceed` or
  `e.cancel` (default blocks). `e.host`, `e.error`.
- `on_permission(e)` — camera/microphone request; `e.grant` or `e.deny`
  (default denies). `e.origin`, `e.type` (`:camera`/`:microphone`/
  `:camera_and_microphone`).
- JS dialogs (`alert`/`confirm`/`prompt`) show a native `NSAlert`.

### Hardware video (MSE/EME, e.g. YouTube)

Hardware-composited video only paints into the off-screen capture while
the host window is scanned out by the window server, which does not happen
for the fully off-screen default. Set `video_capture = true` to enable it:

```ruby
web = Reflex::WebView.new {set video_capture: true}
# or: web.video_capture = true
```

The macOS backend then keeps a single, rounded-away (invisible) pixel of
the host window on screen so the video keeps compositing. Off by default.

## Known limitations

- **Platform** — only the macOS (`WKWebView`) backend exists today;
  Windows / Linux (CEF) is planned.
- **`file://`** — bare absolute paths load as local files, but full
  `file://` access to sibling resources is limited on the macOS backend.
- **Hardware video** — blank unless `video_capture` is enabled (above).
- **Scrollbars** — macOS overlay scrollbars are not painted into the
  static capture, so there is no persistent scrollbar.
- **`load_html`** — such pages are not added to the history, and reloading
  one navigates to `about:blank`.
- **Named profiles** — `DataStore.load('name')` requires macOS 14+;
  `DataStore.new` (incognito) and `DataStore.default` work everywhere.
- **Dialogs** — `alert`/`confirm`/`prompt` are app-modal (like a browser).
- **IME** — text input via an input method is not supported.
- **Audio** — `playing_audio?` / `mute` rely on private WebKit API
  (guarded), so they may stop working on a future macOS.
- **No `to_pdf`** and **no network interception** on the macOS backend.

## License

MIT License. See [LICENSE](./LICENSE).
