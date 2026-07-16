<h1 align="center">Reflex</h1>

<p align="center">
  <b>A cross-platform GUI and creative-coding toolkit for Ruby</b>
</p>

<p align="center">
  <a href="https://deepwiki.com/xord/reflex"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
  <img src="https://img.shields.io/github/license/xord/reflex" alt="License">
  <img src="https://github.com/xord/reflex/actions/workflows/test.yml/badge.svg" alt="Build Status">
  <img src="https://badge.fury.io/rb/reflexion.svg" alt="Gem Version">
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

> [!IMPORTANT]
> **The gem name is `reflexion`** (not `reflex`) — `gem install reflexion`. The Ruby namespace is `Reflex`.

## ✨ Features

- **Windows and views** — a `Window` with a tree of `View` objects, styled via a lightweight CSS-style mechanism
- **Event-driven runtime** — `Application` run loop with `on_draw`, `on_update`, `on_pointer`, and many more hooks
- **2D physics** — Box2D bindings turn any `View` into a physics body (`ContactEvent`, gravity, fixtures)
- **MIDI I/O** — RtMidi bindings deliver `MidiEvent`, `NoteEvent`, `ControlChangeEvent` to views
- **Live camera capture** — `CaptureEvent` streams frames from a `Rays::Camera`
- **Two complementary APIs** — a full OO API and a Processing-style single-file API

**Reflex** sits on top of the [Rays](https://github.com/xord/rays) drawing engine and is the application layer underneath [Processing](https://github.com/xord/processing), [RubySketch](https://github.com/xord/rubysketch), and [Reight](https://github.com/xord/reight).

> [!NOTE]
> Like the rest of the `xord/*` family, Reflex is primarily developed for our own use, but it also works as a standalone GUI / creative-coding toolkit.

## 📦 Installation

Add this line to your Gemfile:
```ruby
gem 'reflexion'
```

Then install:
```bash
$ bundle install
```

Or install it directly:
```bash
$ gem install reflexion
```

> [!TIP]
> `require 'reflex'` automatically calls `Reflex.init!` (and `Rays.init!`) and registers `Reflex.fin!` at exit. Set `$REFLEX_NOAUTOINIT = true` before requiring if you want to manage the lifetime yourself.

### Requirements

- Ruby **3.0.0** or later
- A C++ compiler with C++20 support
- [Xot](https://rubygems.org/gems/xot), [Rucy](https://rubygems.org/gems/rucy), and [Rays](https://rubygems.org/gems/rays) (declared as runtime dependencies)
- Platform GUI backend:
  - **macOS** — AppKit (bundled with the OS)
  - **iOS** — UIKit (bundled with the OS)
  - **Windows** — native Win32
  - **Linux** — `libsdl2-dev`

The following third-party libraries are cloned from GitHub and statically linked while the native extension is being built:

| Library                                       | Role                                |
| --------------------------------------------- | ----------------------------------- |
| [Box2D](https://github.com/erincatto/box2d)   | 2D physics simulation (`View` bodies, `ContactEvent`, gravity, fixtures) |
| [RtMidi](https://github.com/thestk/rtmidi)    | MIDI I/O — exposes `MidiEvent`, `NoteEvent`, `ControlChangeEvent` to views |

## 🚀 Quick Start

Hello, Reflex (OO style):

```ruby
require 'reflex'

class HelloWindow < Reflex::Window
  def initialize
    super title: 'Hello Reflex!', frame: [100, 100, 320, 240]
    painter.font = Reflex::Font.new('Menlo', 32)
    painter.background = 0
    painter.fill = 1
  end

  def on_draw(e)
    e.painter.text 'hello world!', 5, 5
  end

  def on_update(e)
    painter.background = rand, rand, rand
    redraw
  end
end

Reflex.start do
  HelloWindow.new.show
end
```

Run it with `$ ruby hello.rb` — a window appears, that's all it takes.

## 💡 Examples

### Block / DSL style

```ruby
require 'reflex'

Reflex.start do
  Reflex::Window.show title: 'Shapes', frame: [100, 100, 500, 300] do
    def on_draw(e)
      e.painter.push do
        fill   :pink
        stroke 1
        stroke_width 2
        rect    10, 10, 80, 80, 10
        ellipse 120, 10, 80, 80
      end
    end
  end
end
```

### Reflexion (Processing-style single-file)

```ruby
require 'reflexion/include'

setup do
  window.title = 'Reflexion!'
end

draw do |p|
  p.background 0
  p.fill 1
  p.text 'hello from reflexion', 10, 30
end

pointer do |e|
  puts "pointer at #{e.pos.to_a.inspect}"
end
# Reflexion.start is called automatically at_exit
```

### 2D physics with Box2D

```ruby
require 'reflex'

Reflex.start name: 'Physics' do |app|
  Reflex::Window.show title: app.name, frame: [100, 100, 500, 500] do
    gravity 0, 9.8 * meter

    50.times do
      add Reflex::View.new {
        pos        rand(10..400), rand(10..100)
        size       rand(5..50)
        background [:red, :green, :blue, :yellow, :orange].sample
        dynamic    true
        shape      Reflex::EllipseShape.new(density: 1)
      }
    end

    add Reflex::View.new {     # a static ground
      pos        0, 480
      size       500, 20
      background :darkgray
      static     true
    }

    on :pointer do |e|
      if e.down? || e.drag?
        add Reflex::View.new(pos: e.pos, size: 10, dynamic: true,
                             shape: Reflex::EllipseShape.new(density: 1))
      end
    end
  end
end
```

See the [`samples/`](./samples) directory for more examples covering shapes, layout, models, MIDI, camera capture, etc.

## 📚 What's Included

### Two ways to use the gem

The gem ships **two complementary APIs**:

1. **`require 'reflex'`** — the full OO API. Subclass `Reflex::Window`, override `on_draw` / `on_update` / `on_pointer`, build a view hierarchy, etc.
2. **`require 'reflexion/include'`** — a single-file, Processing-style API that exposes top-level `setup`, `draw`, `update`, `key`, `pointer`, `motion` blocks and auto-starts the application on `at_exit`.

### Application / Window / View

| Class                    | Purpose                                                                 |
| ------------------------ | ----------------------------------------------------------------------- |
| `Reflex::Application`    | Run loop; created and started by `Reflex.start { ... }`                 |
| `Reflex::Window`         | OS-level window with title, frame, flags (closable / resizable / fullscreen / portrait / landscape) |
| `Reflex::View`           | Recursive UI node: position, size, transform, styles, child views, optional clipping / caching |
| `Reflex::Screen`         | Information about a display monitor                                     |
| `Reflex::Timer`          | One-shot or interval timer that delivers `TimerEvent`                   |

### Shapes (drawing + physics body)

A view can carry one or more `Shape` objects that act both as its drawn appearance and as its physics fixture. Built-ins:

- `Reflex::RectShape`
- `Reflex::EllipseShape`
- `Reflex::LineShape`
- `Reflex::PolygonShape` — wraps a `Rays::Polygon`

### Events

Every event class inherits from `Reflex::Event`. Views receive them via `on_<name>` hooks (or `on(:name)` / `before(:name)` / `after(:name)` from `Xot::Hookable`).

| Event class                                          | View hook            | When it fires                                       |
| ---------------------------------------------------- | -------------------- | --------------------------------------------------- |
| `UpdateEvent`                                        | `on_update`          | Every frame, before drawing                         |
| `DrawEvent`                                          | `on_draw`            | Every frame, to render with `e.painter`             |
| `FrameEvent`                                         | `on_frame_*`         | Frame resize / move                                 |
| `FocusEvent`                                         | `on_focus`           | Keyboard focus gained / lost                        |
| `KeyEvent`                                           | `on_key`             | Key down / up / repeat                              |
| `PointerEvent`                                       | `on_pointer`         | Mouse / touch down / move / up                      |
| `WheelEvent`                                         | `on_wheel`           | Scroll wheel / trackpad scroll                      |
| `ScrollEvent`                                        | `on_scroll`          | The view itself scrolled                            |
| `MidiEvent` / `NoteEvent` / `ControlChangeEvent`     | `on_midi` / `on_note` / `on_control_change` | Incoming MIDI message |
| `CaptureEvent`                                       | `on_capture`         | New frame from a `Rays::Camera`                     |
| `TimerEvent`                                         | `on_timer`           | Fired by `start_timer` / `start_interval`           |
| `ContactEvent`                                       | `on_contact_*`       | Two physics bodies began / ended overlapping        |
| `DeviceEvent` / `MotionEvent`                        | various              | Device-level signals (accelerometer / gyro / connection) |

### Styling and selectors

`Reflex::Style` and `Reflex::Selector` (with `HasSelector`) provide a lightweight CSS-style mechanism for setting background, padding, layout, etc., on views.

## 🧩 Part of the xord family

Reflex is the application layer of the `xord/*` stack — built on the [Rays](https://github.com/xord/rays) drawing engine, and underneath Processing, RubySketch, and Reight:

[`xot`](https://github.com/xord/xot) → [`rucy`](https://github.com/xord/rucy) → [`rays`](https://github.com/xord/rays) → `reflex` → [`processing`](https://github.com/xord/processing) → [`rubysketch`](https://github.com/xord/rubysketch) → [`reight`](https://github.com/xord/reight)

## 🛠️ Development

```bash
$ rake vendor   # clone Box2D and RtMidi into vendor/
$ rake lib      # build the native C++ library (libreflex)
$ rake ext      # build the Ruby C extension
$ rake test     # run the test suite
$ rake doc      # generate RDoc from C++ sources
$ rake          # default: builds the extension
```

The test suite requires a windowing system, so CI only runs it on macOS. The `test_reflex_init.rb` test must run in its own process and is listed in `TESTS_ALONE`.

In the [`xord/all`](https://github.com/xord/all) monorepo you can scope by module, e.g. `rake reflex test`.

## 📜 License

**Reflex** is licensed under the MIT License.
See the [LICENSE](./LICENSE) file for details.

The third-party libraries listed above retain their own licenses (Box2D: MIT, RtMidi: MIT-style).
