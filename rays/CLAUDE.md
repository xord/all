# Rays

OpenGL-based 2D drawing engine.

## External Libraries

Automatically fetched at build time:
- GLM 1.0.1 — Math library
- Clipper 6.4.2 — Polygon clipping
- Earcut.hpp v2.2.4 — Polygon triangulation
- Splines-lib — Filtering
- STB (Windows/Linux only) — Image loading

## Platform-Specific Code

Platform implementations under `src/`:
- `src/osx/` — macOS (AppKit, OpenGL)
- `src/ios/` — iOS
- `src/win32/` — Windows (GDI32, OpenGL32)
- `src/sdl/` — Linux (SDL2, GLEW)

## Testing

- `test_rays_init.rb` must run alone (`TESTS_ALONE`)
- `assert_equal_color` — Custom color comparison assertion
