# Rays

OpenGL ベースの 2D 描画エンジン。

## 外部ライブラリ

ビルド時に自動取得:
- GLM 1.0.1 — 数学ライブラリ
- Clipper 6.4.2 — ポリゴンクリッピング
- Earcut.hpp v2.2.4 — ポリゴン三角形分割
- Splines-lib — フィルタリング
- STB (Windows/Linux のみ) — 画像読み込み

## プラットフォーム固有コード

`src/` 以下にプラットフォーム別実装がある:
- `src/osx/` — macOS (AppKit, OpenGL)
- `src/ios/` — iOS
- `src/win32/` — Windows (GDI32, OpenGL32)
- `src/sdl/` — Linux (SDL2, GLEW)

## テスト

- `test_rays_init.rb` は単独実行が必要（`TESTS_ALONE`）
- `assert_equal_color` — カスタムカラー比較アサーション
