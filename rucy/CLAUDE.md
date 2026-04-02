# Rucy

Ruby C++ Extension Helper Library。Ruby 拡張を C++ で書く際のボイラープレートを削減する。

## ERB テンプレートによるコード生成

`src/*.cpp.erb` と `include/rucy/*.h.erb` は ERB テンプレートで、ビルド時に展開される。
`NPARAM_MAX = 12` により 0〜12 引数の関数バインディングを自動生成する。

## マクロ API

C++ 側で Ruby メソッドを定義する際は専用マクロを使う:
```cpp
RUCY_DEF0(method_name)
{
  // ...
}
RUCY_END
```

## ツール

- `bin/rucy2rdoc` — C++ ドキュメントマクロを RDoc に変換
