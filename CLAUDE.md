# CLAUDE.md

This repository (xord/all) is a monorepo of core libraries.

## Module Structure

Each library lives at the repository root:
`xot`, `rucy`, `beeps`, `rays`, `reflex`, `processing`, `rubysketch`, `reight`

Each module follows this layout:
- `src/`, `include/` — C/C++
- `ext/` — Ruby extension library
- `lib/` — Ruby code
- `test/` — Unit tests
- `samples/`, `examples/` — Examples

A shared Rakefile delegates build and test tasks per module.
`.hooks/` and `.workflows/` generate Git hooks and CI definitions and distribute them to each module.

## Build & Test

```bash
# Build C/C++ libraries
rake lib

# Build extension libraries
rake ext

# Run tests
rake test

# Test a specific module
rake rays test

# Build specific modules only
rake rays reflex ext

# Run a sample
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
