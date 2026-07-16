<h1 align="center">Reight</h1>

<p align="center">
  <b>A retro game engine for Ruby — a fantasy console with built-in sprite, map, and sound editors</b>
</p>

<p align="center">
  <a href="https://deepwiki.com/xord/reight"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
  <img src="https://img.shields.io/github/license/xord/reight" alt="License">
  <img src="https://github.com/xord/reight/actions/workflows/test.yml/badge.svg" alt="Build Status">
  <img src="https://badge.fury.io/rb/reight.svg" alt="Gem Version">
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

- **A fixed 400 × 224 screen** — a retro-friendly framebuffer, upscaled with no smoothing for a crisp pixel-art look
- **A 32-color palette** — transparent first, then a PICO-8-flavored set
- **8 × 8 pixel chips** — a chip / tileset system with a chunked tile map
- **Built-in sprite / map / sound editors** — author all assets without leaving the tool, via the `r8` command
- **Plain-file projects** — a project is just a directory of JSON and PNG files
- **The full Processing + RubySketch API** — Reight's runtime is essentially [RubySketch](https://github.com/xord/rubysketch) (and [Processing](https://github.com/xord/processing) under it), restricted to the retro framebuffer and extended with project storage and an editing UI

**Reight** is a small, fantasy-console-style game engine for Ruby, sitting at the top of the `xord/*` stack.

## 📦 Installation

Add this line to your Gemfile:
```ruby
gem 'reight'
```

Then install:
```bash
$ bundle install
```

Or install it directly:
```bash
$ gem install reight
```

The gem also installs a `r8` command-line tool used to run and edit projects.

### Requirements

- Ruby **3.0.0** or later
- All the runtime requirements of [Reflex](https://github.com/xord/reflex) (Rays, Rucy, Xot, plus the platform GUI backend — AppKit / UIKit / Win32 / SDL2 — and OpenGL)
- The dependent gems are installed automatically: `xot`, `rucy`, `beeps`, `rays`, `reflexion`, `processing`, `rubysketch`

There is no native C/C++ extension in this gem; the heavy lifting is done by the underlying gems' extensions.

## 🚀 Quick Start

A minimal `game.rb`:

```ruby
draw do
  background 0
  fill 1
  text 'hello, reight!', 10, 100
end
```

Run it from the project directory:

```bash
$ r8 .
```

## ▶️ The `r8` command

```bash
$ r8 [DIR]              # run the project in DIR (default: current directory)
$ r8 --edit [DIR]       # open the project in the built-in editor
$ r8 --help             # show all options
```

`DIR` is the project directory. A project is just a directory of plain files:

```
mygame/
├── project.json   # screen size, font, file names, ...
├── game.rb        # your game code (uses Reight's top-level API)
├── chips.png      # tileset image
├── chips.json     # tile metadata (shapes, sensors, ...)
├── maps.json      # tile-map data (chunked)
└── sounds.json    # sound data
```

If it does not contain a `project.json`, defaults are used.

### Built-in editor screens

When launched with `--edit`, the engine adds these tabs alongside the game runner:

| Editor       | Purpose                                                          | Tools (`lib/reight/app/<name>/`) |
| ------------ | ---------------------------------------------------------------- | -------------------------------- |
| **Sprite**   | Pixel-art editor for the chip / tileset image (`chips.png`)      | brush, fill, color picker, line, rect / shape, select |
| **Map**      | Chunk-based tile-map editor                                      | brush, line, rect                |
| **Sound**    | Waveform-based sound editor                                      | brush, eraser                    |

The currently active tab is switched from the top navigator bar.

## 💡 Examples

### Move a sprite with the cursor keys

```ruby
player = createSprite 200, 112, 8, 8

player.update do
  player.x += 1 if key_is_down(RIGHT)
  player.x -= 1 if key_is_down(LEFT)
end

draw do
  background 0
  sprite player
end
```

### Draw the first map of the project

```ruby
draw do
  background 0
  $sprites ||= project.maps.first.to_sprites
  sprite *$sprites
end
```

(Open `r8 --edit .` first to draw the map, then run `r8 .` to play it.)

### Use chip properties

Chips have a `props` hash you can read from your game code:

```ruby
$sprites ||= project.maps.first.to_sprites.each do |sp|
  sp.dynamic = true if sp.chip.props[:dynamic]
end
```

## 📚 What's Included

`require 'reight'` makes a refinement-based API available, much like Processing and RubySketch. The full **Processing + RubySketch** vocabulary is exposed at the top level (camelCase **and** snake_case aliases), and Reight adds the pieces below.

### Reight-specific API

| API                  | Purpose                                                                                                  |
| -------------------- | -------------------------------------------------------------------------------------------------------- |
| `project`            | The active `Reight::Project` — accessors for `chips`, `maps`, `sounds`, project paths, font, etc.        |
| `Reight::Sprite`     | A subclass of `RubySketch::Sprite` carrying an optional `chip` and a per-instance `props` hash; default sprite class returned by `createSprite` inside Reight |
| `Reight::Chip`       | A single tile from the tileset — `id`, position / size in `chips.png`, optional collision shape and sensor flag |
| `Reight::Map`        | Chunk-based tile map (`chip_size: 8`, `chunk_size: 128` by default); `Enumerable`, with `to_sprites` and live `activate(x, y, w, h, world)` for visible regions |
| `Reight::Sound`      | Persistent sound asset, edited by the Sound editor                                                       |
| `Reight::Project`    | Loads and saves the JSON / PNG files described above                                                     |

### Constants on `Reight::App`

| Constant            | Value      | Meaning                                                              |
| ------------------- | ---------- | -------------------------------------------------------------------- |
| `SCREEN_WIDTH`      | `400`      | Fixed framebuffer width                                              |
| `SCREEN_HEIGHT`     | `224`      | Fixed framebuffer height                                             |
| `PALETTE_COLORS`    | 32 entries | Default 32-color hex palette (transparent first, then a PICO-8-flavored set) |

The window opens at `3×` the framebuffer size by default; the framebuffer is upscaled with no smoothing for a crisp pixel-art look.

## 🧩 Part of the xord family

Reight sits at the top of the `xord/*` stack, built on RubySketch and Processing:

[`xot`](https://github.com/xord/xot) → [`rucy`](https://github.com/xord/rucy) → [`beeps`](https://github.com/xord/beeps) / [`rays`](https://github.com/xord/rays) → [`reflex`](https://github.com/xord/reflex) → [`processing`](https://github.com/xord/processing) → [`rubysketch`](https://github.com/xord/rubysketch) → `reight`

## 🛠️ Development

```bash
$ rake test    # run the test suite
$ rake doc     # generate YARD docs
$ rake         # default tasks
```

In the [`xord/all`](https://github.com/xord/all) monorepo you can scope by module, e.g. `rake reight test`.

There is also a WASM build pipeline under [`wasm/`](./wasm) that packages the engine and your project for the browser via Emscripten + ruby.wasm.

## 📜 License

**Reight** is licensed under the MIT License.
See the [LICENSE](./LICENSE) file for details.
