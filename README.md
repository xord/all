# Reflex Terminal - A terminal emulator for Reflex

**Status: Usable, but the API is not stable yet.**

reflex-terminal provides a terminal emulator for the
[Reflex](https://github.com/xord/reflex) GUI toolkit:

- `Reflex::Terminal` — a headless terminal emulator model. It spawns a shell
  on a PTY and maintains the screen state (cells, colors, scrollback, reflow
  on resize) using [libghostty-vt](https://libghostty.tip.ghostty.org/),
  the terminal emulation core extracted from
  [Ghostty](https://github.com/ghostty-org/ghostty).
- `Reflex::TerminalView` — a `Reflex::View` that renders a `Terminal` and
  feeds keyboard / mouse input into it.

Full-screen programs work: emacs and mouse-driven terminal multiplexers run
in it, with colors, CJK text, reflow on resize and scrollback.

## Usage

```ruby
require 'reflex-terminal'

win = Reflex::Window.new {
  title 'Terminal'
  frame 100, 100, 720, 450
}
win.add Reflex::TerminalView.new
win.show

Reflex.start
```

See `examples/terminal.rb`.

### Without a child process

A `Terminal` does not have to run a shell. Feed it bytes and it renders
whatever speaks terminal escape sequences — a build log, a recorded
session — with its colors and cursor motion applied:

```ruby
t = Reflex::Terminal.new 120, 40
t.feed File.binread('build.log')
t.update
puts t.lines
```

Driving an interactive program over your own transport takes one more call:
`#read_pending_input` hands back the bytes the terminal wants to send
upstream, which are the query responses it generates on its own plus any
encoded key and mouse events.

## Requirements

- macOS, Linux or Windows
- Ruby 3.0+
- [Zig](https://ziglang.org/) **0.16.0** — required to build libghostty-vt
  from source into `vendor/ghostty/`. On macOS `rake packages` installs it
  through Homebrew; elsewhere take the 0.16.0 build for your platform from
  the [downloads page](https://ziglang.org/download/) and put it on `PATH`,
  since packaged versions rarely match the one the pinned ghostty commit
  asks for.

## Build

```bash
$ rake packages   # macOS: installs zig through Homebrew
$ rake ext        # clones + builds libghostty-vt (first time only), then the extension
$ rake test
```

## Limitations

- No input method support, so Japanese and other composed text cannot be
  typed. Reflex hands key events straight to the view without going through
  the platform's input context, which is where composition would start.
- On Linux, `TerminalView` needs a font handed to it (`font:` with a
  `Rays::Font` or a path). Rays cannot look one up by name there, so the
  default font name does not resolve.
- On Windows, the single-string form of `Terminal#spawn` cannot contain
  quotes. It runs through `cmd.exe /c`, which does not understand the
  backslash escaping that the command line is built with. Pass the command
  as separate arguments instead.
- No image protocols (Kitty graphics, Sixel).
- No selection or copy UI. `#lines` and `#each_history_line` return the text.

## Updating the vendored libghostty-vt

libghostty-vt is under active development and has no standalone releases yet
(ghostty release tags up to v1.3.1 do not contain the terminal C APIs), so
this gem pins a verified commit of ghostty's main branch: see the `commit:`
given to `use_external_library` in `Rakefile`. To update:

1. Bump that commit (check `minimum_zig_version` in ghostty's
   `build.zig.zon` still matches the installed Zig)
2. `rake vendor:ghostty:update`
3. `rake ext test`

Once libghostty-vt gets standalone releases, switch the pin to a release tag.
