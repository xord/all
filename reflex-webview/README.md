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

The rendering backend depends on the platform:

- **macOS** — `WKWebView` rendered off-screen and captured into a texture.
- **Windows / Linux** — Chromium Embedded Framework (CEF).

## License

MIT License. See [LICENSE](./LICENSE).
