# CLAUDE.md

このリポジトリ (xord/all) は Ruby 向けの主要ライブラリをまとめたモノレポです。

## モジュール構成

ルート直下に各ライブラリが配置されています:
`xot`, `rucy`, `beeps`, `rays`, `reflex`, `processing`, `rubysketch`, `reight`

各モジュールの構造:
- `src/`, `include/` — C/C++
- `ext/` — Ruby 拡張ライブラリー
- `lib/` — Ruby コード
- `test/` — ユニットテスト
- `samples/`, `examples/` — 実行例

共通の Rakefile がモジュール単位のビルド・テストを委譲します。
`.hooks/` と `.workflows/` は Git フックと CI 定義を生成して各モジュールに配布します。

## ビルド・テスト

```bash
# 依存関係のインストール
bundle install

# C/C++ ライブラリのビルド
bundle exec rake lib

# 拡張ライブラリのビルド
bundle exec rake ext

# テスト実行
bundle exec rake test

# 個別モジュールのテスト
bundle exec rake rays test

# 対象を絞ったビルド
bundle exec rake rays reflex ext

# サンプル実行
bundle exec rake run sample=hello
```

## コーディングスタイル

### C/C++
- タブによるインデント
- インデント以外の空白調整は空白文字
- ヘッダーは `<xot/...>` 形式で参照
- クラス名は `CamelCase`、メンバは `snake_case`

### Ruby
- 2 スペースインデント
- `snake_case` メソッド名、`SCREAMING_SNAKE_CASE` 定数
- 既存ファイルの require 順序とガード節のスタイルを踏襲

## テスト

- `test/` ディレクトリに `test_対象名.rb` の命名で配置
- C 拡張を伴う変更では Ruby とネイティブ両方のカバレッジを持たせる
- 新しい API には正のテスト + エラーハンドリングケースを最低 1 件追加
- `bundle exec rake test` がローカルで緑になってから PR を出す

## コミット

- 命令形の 1 行サマリ: `Add feature`, `Fix issue`
- 関連モジュール名を先頭に付ける（例: `rays: Fix rendering bug`）
