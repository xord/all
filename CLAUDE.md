# CLAUDE.md

This repository (xord/all) is a monorepo of core libraries.

## Module Structure

Each library lives at the repository root.

Ruby gems (published to RubyGems):
`xot`, `rucy`, `beeps`, `rays`, `rays-video`, `reflex` (gem name: `reflexion`),
`processing`, `rubysketch`, `reight`

Native runtime distributed as a CocoaPod (not a gem):
`cruby` — embeds CRuby (MRI) into macOS / iOS apps; Objective-C.

Each Ruby gem module follows this layout:
- `src/`, `include/` — C/C++
- `ext/` — Ruby extension library
- `lib/` — Ruby code
- `test/` — Unit tests
- `samples/`, `examples/` — Examples
- `vendor/` — Cloned upstream third-party libs (populated by `rake vendor`)

`cruby` differs: Objective-C source under `src/`, headers under `include/`,
the framework is built via `rake build` and consumed via `CRuby.podspec`.

A shared Rakefile delegates build and test tasks per module.
- `.hooks/` — Source Git hook scripts, distributed into each module's `.git/hooks/`
- `.workflows/` — Source GitHub Actions workflow templates, distributed into each module's `.github/workflows/`

## Build & Test

The root Rakefile delegates to per-module Rakefiles. Without a scope it
operates on all gems; pass a module name (or a scope selector) to narrow it.

```bash
# Build everything (all gems)
rake lib            # C/C++ libraries
rake ext            # Ruby native extensions
rake test           # run tests

# Scope to one or more modules
rake rays test
rake rays reflex ext
rake xot rucy beeps lib

# Scope selectors
rake :all  test     # all repos including cruby
rake :exts test     # only modules with a native extension
rake :gems test     # all published Ruby gems (same as default)

# Other useful tasks
rake vendor         # clone third-party libs into each module's vendor/
rake erb            # expand ERB-templated headers (mostly rucy)
rake gem            # build .gem files
rake install        # gem install built gems
rake clean
rake clobber

# Run a Reflex sample
rake run sample=hello
```

## Coding Style

### C/C++
- Tab indentation
- Spaces for alignment beyond indentation
- Headers referenced as `<xot/...>`
- Class names: `CamelCase`, members: `snake_case`

### Ruby
- 2-space indentation
- `snake_case` methods, `SCREAMING_SNAKE_CASE` constants
- Follow existing require order and guard clause style

## Testing

- Place tests in `test/` as `test_<name>.rb`
- Changes involving C extensions need both Ruby and native coverage
- New APIs require at least one positive test + one error handling case
- Ensure `bundle exec rake test` passes locally before submitting a PR

## Commits

- Imperative one-line summary: `Add feature`, `Fix issue`
- Prefix with module name (e.g., `rays: Fix rendering bug`)
