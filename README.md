# Reflex Terminal - A terminal emulator for Reflex

**Status: Work in progress. Nothing is usable yet.**

reflex-terminal provides a terminal emulator for the
[Reflex](https://github.com/xord/reflex) GUI framework:

- `Reflex::Terminal` — a headless terminal emulator model. It spawns a shell
  on a PTY and maintains the screen state (cells, colors, scrollback, reflow
  on resize) using [libghostty-vt](https://libghostty.tip.ghostty.org/),
  the terminal emulation core extracted from
  [Ghostty](https://github.com/ghostty-org/ghostty).
- `Reflex::TerminalView` — a `Reflex::View` that renders a `Terminal` and
  feeds keyboard / mouse input into it.

## Requirements

- macOS (for now)
- Ruby 3.0+
- [Zig](https://ziglang.org/) **0.16.0** (`brew install zig`) — required to
  build libghostty-vt from source into `vendor/ghostty/`

## Build

```bash
$ rake packages   # installs zig via Homebrew
$ rake ext        # clones + builds libghostty-vt (first time only), then the extension
$ rake test
```

## Updating the vendored libghostty-vt

libghostty-vt is under active development and has no standalone releases yet
(ghostty release tags up to v1.3.1 do not contain the terminal C APIs), so
this gem pins a verified commit of ghostty's main branch: see
`GHOSTTY_COMMIT` in `Rakefile`. To update:

1. Bump `GHOSTTY_COMMIT` (check `minimum_zig_version` in ghostty's
   `build.zig.zon` still matches the installed Zig)
2. `rake vendor:ghostty:update`
3. `rake ext test`

Once libghostty-vt gets standalone releases, switch the pin to a release tag.
