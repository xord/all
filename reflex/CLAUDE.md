# Reflex

Ruby 向け GUI ツールキット。Window と View を中心としたイベント駆動アーキテクチャ。

## gem 名

公開 gem 名は **`reflexion`**（`reflex` ではない）。

## 外部ライブラリ

- Box2D v2.4.1 — 物理エンジン
- RtMidi 6.0.0 — MIDI デバイスサポート

## プラットフォーム固有コード

`src/` 以下:
- `src/osx/` — macOS
- `src/ios/` — iOS
- `src/win32/` — Windows
- `src/sdl/` — Linux (SDL2)

## イベントシステム

19 種以上のイベント型（KeyEvent, PointerEvent, DrawEvent, MidiEvent 等）。
View のフックメソッド: `on_draw`, `on_update`, `on_key`, `on_pointer` など。

## テスト

- `test_reflex_init.rb` は単独実行が必要（`TESTS_ALONE`）
- CI は macOS のみ（GUI が必要なため）
