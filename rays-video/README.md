<h1 align="center">Rays Video</h1>

<p align="center">
  <b>Video reading, writing, and frame-level manipulation for <a href="https://github.com/xord/rays">Rays</a></b>
</p>

<p align="center">
  <a href="https://deepwiki.com/xord/rays-video"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
  <img src="https://img.shields.io/github/license/xord/rays-video" alt="License">
  <img src="https://github.com/xord/rays-video/actions/workflows/test.yml/badge.svg" alt="Build Status">
  <img src="https://badge.fury.io/rb/rays-video.svg" alt="Gem Version">
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

- **Frames as images** — a `Rays::Video` is, conceptually, an ordered list of `Rays::Image` frames with a frame rate and a pixel density
- **Build from scratch** — create an empty video and append / insert / remove frames
- **File I/O** — load a video from disk and save it back out
- **Playback** — scrub a playback position, play / pause / stop, adjust the time scale
- **Frame extraction** — grab any frame as a regular `Rays::Image` to draw with
- **Audio support** — built on [Beeps](https://github.com/xord/beeps); video files keep their audio track and it can be fed into a Beeps processor chain

**Rays Video** is a small extension to [Rays](https://github.com/xord/rays).

> [!NOTE]
> Like the rest of the `xord/*` family, this gem is primarily developed for our own use, but it works as a standalone video gem.

> [!WARNING]
> **Platform status:** macOS / iOS only at the moment. Windows and Linux backends are not yet implemented.

## 📦 Installation

Add this line to your Gemfile:
```ruby
gem 'rays-video'
```

Then install:
```bash
$ bundle install
```

Or install it directly:
```bash
$ gem install rays-video
```

### Requirements

- Ruby **3.0.0** or later
- A C++ compiler with C++20 support
- [Xot](https://rubygems.org/gems/xot), [Rucy](https://rubygems.org/gems/rucy), [Beeps](https://rubygems.org/gems/beeps), and [Rays](https://rubygems.org/gems/rays) (declared as runtime dependencies)
- **macOS / iOS** — AVFoundation (bundled with the OS)

## 🚀 Quick Start

Build a video from frames and save it:

```ruby
require 'rays'
require 'rays/video'

video = Rays::Video.new(320, 240, fps: 30)

60.times do |n|
  frame = Rays::Image.new(320, 240)
  frame.paint do |p|
    p.background 0
    p.fill 1, 0.5, 0.1
    p.ellipse n * 5, 120, 60, 60
  end
  video.append frame
end

video.save 'out.mp4'
```

Run it with `$ ruby hello.rb` — that's all it takes.

## 💡 Examples

### Load a video and draw a frame

```ruby
require 'rays'
require 'rays/video'

video = Rays::Video.load 'clip.mp4'
puts "#{video.width}×#{video.height} @ #{video.fps}fps, #{video.size} frames"

# get the 30th frame as an Image and save it
video[30].save 'frame30.png'
```

### Scrub through a video

```ruby
video = Rays::Video.load 'clip.mp4'

video.pos = 0
target = Rays::Image.new video.width, video.height
target.paint do |p|
  p.image video.to_image
end

video.pos = video.size / 2     # mid-point
mid = video.to_image
```

## 📚 What's Included

### `Rays::Video`

A finite sequence of `Rays::Image` frames with a fixed `width`, `height`, `fps`, and `pixel_density`.

| Method                                     | Purpose                                                            |
| ------------------------------------------ | ------------------------------------------------------------------ |
| `Video.new(width, height, fps:, pixel_density:)` | Create an empty video (`fps` defaults to 30)                 |
| `Video.load(path)`                         | Load a video file from disk                                        |
| `Video.exts`                               | Supported video file extensions on the current platform            |
| `video.append(*images)`                    | Append one or more frames                                          |
| `video.insert(index, *images)`             | Insert frames at the given index                                   |
| `video.remove(index)`                      | Remove the frame at the given index                                |
| `video.each { \|image\| ... }`             | Iterate frames (also includes `Enumerable`)                        |
| `video[i]`                                 | Get the frame at index *i* as a `Rays::Image`                      |
| `video.pos` / `video.pos =`                | Current playback position (index)                                  |
| `video.play` / `video.pause` / `video.stop`| Playback controls                                                  |
| `video.time_scale` / `video.time_scale =`  | Speed multiplier for playback                                      |
| `video.size`, `video.empty?`               | Frame count / emptiness                                            |
| `video.width`, `video.height`, `video.fps`, `video.pixel_density` | Read-only metadata                          |
| `video.dup`                                | Deep-ish copy (shares image references)                            |
| `video.save(path)`                         | Encode the video to a file                                         |
| `video.to_image` (`Image()` cast)          | Get the frame at the current `pos` as a `Rays::Image`              |

## 🧩 Part of the xord family

Rays Video extends [Rays](https://github.com/xord/rays) with video support, and leans on [Beeps](https://github.com/xord/beeps) for audio:

[`xot`](https://github.com/xord/xot) → [`rucy`](https://github.com/xord/rucy) → [`beeps`](https://github.com/xord/beeps) / [`rays`](https://github.com/xord/rays) → `rays-video`

## 🛠️ Development

```bash
$ rake lib    # build the native C++ library (librays-video)
$ rake ext    # build the Ruby C extension
$ rake test   # run the test suite (macOS / iOS only)
$ rake doc    # generate RDoc from C++ sources
$ rake       # default: builds the extension
```

In the [`xord/all`](https://github.com/xord/all) monorepo you can scope by module, e.g. `rake rays-video test`.

## 📜 License

**Rays Video** is licensed under the MIT License.
See the [LICENSE](./LICENSE) file for details.
