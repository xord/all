# Reflex

GUI toolkit for Ruby. Event-driven architecture centered on Window and View.

## Gem Name

The published gem name is **`reflexion`** (not `reflex`).

## External Libraries

- Box2D v2.4.1 — Physics engine
- RtMidi 6.0.0 — MIDI device support

## Platform-Specific Code

Under `src/`:
- `src/osx/` — macOS
- `src/ios/` — iOS
- `src/win32/` — Windows
- `src/sdl/` — Linux (SDL2)

## Event System

19+ event types (KeyEvent, PointerEvent, DrawEvent, MidiEvent, etc.).
View hook methods: `on_draw`, `on_update`, `on_key`, `on_pointer`, etc.

## Testing

- `test_reflex_init.rb` must run alone (`TESTS_ALONE`)
- CI runs on macOS only (requires GUI)
