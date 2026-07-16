<h1 align="center">Rays</h1>

<p align="center">
  <b>A hardware-accelerated 2D drawing engine for Ruby, built on OpenGL</b>
</p>

<p align="center">
  <a href="https://deepwiki.com/xord/rays"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
  <img src="https://img.shields.io/github/license/xord/rays" alt="License">
  <img src="https://github.com/xord/rays/actions/workflows/test.yml/badge.svg" alt="Build Status">
  <img src="https://badge.fury.io/rb/rays.svg" alt="Gem Version">
</p>

<p align="center">
  <a href="#-installation">Installation</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-whats-included">What's Included</a> •
  <a href="#%EF%B8%8F-development">Development</a> •
  <a href="#-license">License</a>
</p>

---

> [!IMPORTANT]
> **This repository is a read-only mirror.** All development happens in the
> [xord/all](https://github.com/xord/all) monorepo — please open issues and
> pull requests there, not here.
> See the [Contribution Guidelines](./CONTRIBUTING.md) for details.

## ✨ Features

- **Hardware-accelerated 2D drawing** — built on OpenGL, rendering into an off-screen `Image` or a window provided by [Reflex](https://github.com/xord/reflex)
- **Retained-mode-friendly API** — build `Polygon`, `Polyline`, `Image`, `Shader`, and `Font` objects, then paint them through a `Painter`
- **Immediate-mode `Painter`** — shapes, text, images, transforms, and push / pop drawing state
- **Polygon Boolean operations** — combine shapes with `+`, `-`, `&`, `|`, `^`
- **GLSL shaders** — fragment / vertex shaders with uniform parameters
- **Live camera capture** — `Rays::Camera` renders camera frames into an `Image`

**Rays** is the rendering layer used by [Reflex](https://github.com/xord/reflex), [Processing](https://github.com/xord/processing), [RubySketch](https://github.com/xord/rubysketch), and [Reight](https://github.com/xord/reight).

> [!NOTE]
> Like the rest of the `xord/*` family, Rays is primarily developed for our own use, but it also works as a standalone drawing gem.

## 📦 Installation

Add this line to your Gemfile:
```ruby
gem 'rays'
```

Then install:
```bash
$ bundle install
```

Or install it directly:
```bash
$ gem install rays
```

> [!TIP]
> `require 'rays'` automatically calls `Rays.init!` and registers `Rays.fin!` at exit. Set `$RAYS_NOAUTOINIT = true` before requiring if you want to manage the lifetime yourself.

> [!NOTE]
> Rays needs a current OpenGL context. When used through [Reflex](https://github.com/xord/reflex), the window creates and binds a context for you. To use Rays standalone for off-screen rendering, it allocates a hidden context automatically.

### Requirements

- Ruby **3.0.0** or later
- A C++ compiler with C++20 support
- [Xot](https://rubygems.org/gems/xot) and [Rucy](https://rubygems.org/gems/rucy) (declared as runtime dependencies)
- Platform graphics backend:
  - **macOS** — AppKit, OpenGL, AVFoundation (bundled with the OS)
  - **iOS** — UIKit, OpenGL ES, AVFoundation (bundled with the OS)
  - **Windows** — GDI32, OpenGL32, GLEW (`MINGW_PACKAGE_PREFIX-glew`)
  - **Linux** — `libsdl2-dev`, `libsdl2-ttf-dev`, `libglew-dev`

The following third-party libraries are cloned from GitHub and statically linked while the native extension is being built, so you do not need to install them separately:

| Library                                                       | Role                                              |
| ------------------------------------------------------------- | ------------------------------------------------- |
| [GLM](https://github.com/g-truc/glm)                          | Vector / matrix math used internally              |
| [Clipper](https://github.com/skyrpex/clipper)                 | Polygon Boolean operations (`+`, `-`, `&`, `\|`, `^`) |
| [earcut.hpp](https://github.com/mapbox/earcut.hpp)            | Polygon triangulation                             |
| [splines-lib](https://github.com/andrewwillmott/splines-lib)  | Curve / spline math                               |
| [stb](https://github.com/nothings/stb) (Windows / Linux only) | Image file loading                                |

## 🚀 Quick Start

Draw to an off-screen image and save it:

```ruby
require 'rays'

image = Rays::Image.new(200, 200)
image.paint do |p|
  p.background 0, 0, 0
  p.fill   1, 0.4, 0.1     # orange-ish
  p.stroke 1, 1, 1
  p.stroke_width 4

  p.rect 20, 20, 160, 160, round: 16
  p.ellipse 100, 100, 60, 60
end

image.save 'out.png'
```

Run it with `$ ruby hello.rb` — that's all it takes.

## 💡 Examples

### Compose a polygon from Boolean operations

```ruby
require 'rays'

a = Rays::Polygon.rect(0, 0, 100, 100)
b = Rays::Polygon.ellipse(50, 50, 80, 80)

union        = a | b   # outer outline of both
difference   = a - b   # rectangle with circular bite
intersection = a & b   # lens-shaped overlap
xor          = a ^ b   # everything except the overlap

Rays::Image.new(140, 140).paint {|p| p.fill 1; p.polygon difference }.save 'diff.png'
```

(The C++ operator names map to Ruby's `|`, `-`, `&`, `^`.)

### Use a fragment shader

```ruby
require 'rays'

invert = Rays::Shader.new <<~GLSL
  uniform sampler2D texture;
  varying vec4 vTexCoord;
  void main() {
    vec4 c = texture2D(texture, vTexCoord.xy);
    gl_FragColor = vec4(1.0 - c.rgb, c.a);
  }
GLSL

src = Rays::Image.load('photo.png')
out = Rays::Image.new(src.width, src.height)
out.paint do |p|
  p.shader = invert
  p.image src
end
out.save 'photo-invert.png'
```

### Drive `push` / `pop` with attributes

```ruby
image.paint do |p|
  p.push(:state, :matrix, fill: [1, 0, 0]) do
    p.translate 50, 50
    p.rotate 30
    p.rect -20, -20, 40, 40
  end
  # fill, state, and matrix are restored here
end
```

## 📚 What's Included

### Geometry and color types

| Class                | Purpose                                                          |
| -------------------- | ---------------------------------------------------------------- |
| `Rays::Point`        | 2D / 3D point with arithmetic operators                          |
| `Rays::Bounds`       | Axis-aligned rectangle (position + size)                         |
| `Rays::Color`        | RGBA color in floating-point components                          |
| `Rays::ColorSpace`   | Pixel format / color space descriptor (RGBA, ARGB, GRAY, ...)    |
| `Rays::Matrix`       | 4×4 transformation matrix                                        |

### Drawing primitives

| Class                | Purpose                                                                                      |
| -------------------- | -------------------------------------------------------------------------------------------- |
| `Rays::Polyline`     | A single open or closed polyline; expandable into a stroked polygon                          |
| `Rays::Polygon`      | One or more polylines forming a closed shape; supports Boolean ops via `+`, `-`, `&`, `\|`, `^` |
| `Rays::Image`        | A renderable texture with an associated `Painter` for off-screen drawing                     |
| `Rays::Bitmap`       | CPU-side pixel buffer that can be uploaded to / downloaded from an `Image`                   |
| `Rays::Font`         | Text rendering — created from a system font name and a size                                  |
| `Rays::Shader`       | GLSL fragment / vertex shader with `set_uniform` / `uniform` for parameters                  |
| `Rays::Camera`       | Live camera capture (per platform) rendered into an `Image`                                  |

### The `Painter`

`Rays::Painter` is the immediate-mode drawing surface. Obtain one through `Image#painter`, then between `painter.paint do |p| ... end` (or `begin_paint` / `end_paint`) issue draw calls:

- **Shapes** — `point`, `line`, `rect`, `ellipse`, `curve`, `bezier`, `triangle`, `quad`, `polygon`
- **Bitmaps & text** — `image`, `text`
- **State** — `fill`, `stroke`, `background`, `stroke_width`, `stroke_cap`, `stroke_join`, `blend_mode`, `clip`, `font`, `texture`, `shader`
- **Transforms** — `translate`, `scale`, `rotate`, `set_matrix`
- **Push / pop** — `push(:state, :matrix)` / `pop`, or the block form `push(fill: ..., stroke: ...) { ... }`

`stroke_cap`, `stroke_join`, `blend_mode`, `texcoord_mode`, `texcoord_wrap` accept symbols (e.g. `:round`, `:miter`, `:multiply`).

### Top-level helpers

- `Rays.init!` / `Rays.fin!` — explicit lifecycle (called automatically on `require`)
- `Rays::Image.load(path)` / `Rays::Image#save(path)` — image file I/O
- `Rays.renderer_info` — debug info about the current OpenGL context

## 🧩 Part of the xord family

Rays is the rendering layer of the `xord/*` stack — built on Xot and Rucy, and drawn on by everything above it:

[`xot`](https://github.com/xord/xot) → [`rucy`](https://github.com/xord/rucy) → `rays` → [`reflex`](https://github.com/xord/reflex) → [`processing`](https://github.com/xord/processing) → [`rubysketch`](https://github.com/xord/rubysketch) → [`reight`](https://github.com/xord/reight)

## 🛠️ Development

```bash
$ rake vendor   # clone the external libraries into vendor/
$ rake lib      # build the native C++ library (librays)
$ rake ext      # build the Ruby C extension
$ rake test     # run the test suite
$ rake doc      # generate RDoc from C++ sources
$ rake          # default: builds the extension
```

The drawing tests render into off-screen images and compare pixels, so they require a working OpenGL context. The `test_rays_init.rb` test must run in its own process and is listed in `TESTS_ALONE`.

In the [`xord/all`](https://github.com/xord/all) monorepo you can scope by module, e.g. `rake rays test`.

## 📜 License

**Rays** is licensed under the MIT License.
See the [LICENSE](./LICENSE) file for details.

The third-party libraries listed above retain their own licenses (all MIT-compatible: MIT, ISC, Boost-1.0, dual-licensed MIT/Happy-Bunny for GLM, Unlicense for splines-lib).
