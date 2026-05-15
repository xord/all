# Xot - Shared utility classes and functions for C++ and Ruby

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/xord/xot)
![License](https://img.shields.io/github/license/xord/xot)
![Build Status](https://github.com/xord/xot/actions/workflows/test.yml/badge.svg)
![Gem Version](https://badge.fury.io/rb/xot.svg)

## ⚠️  Notice

This repository is a read-only mirror of our monorepo.
We do not accept pull requests or direct contributions here.

### 🔄 Where to Contribute?

All development happens in our [xord/all](https://github.com/xord/all) monorepo, which contains all our main libraries.
If you'd like to contribute, please submit your changes there.

For more details, check out our [Contribution Guidelines](./CONTRIBUTING.md).

Thanks for your support! 🙌

## 🚀 About

**Xot** is the foundational utility layer used by every other library in the `xord/*` family — Rucy, Beeps, Rays, Reflex, Processing, RubySketch, and Reight.

It is split into two layers that ship in a single gem:

- **C++ headers and library** (`include/xot/`, `src/`) — building blocks such as reference counting, the pimpl idiom, non-copyable base, plus thin wrappers for strings, time, exceptions, and debug output. These are linked into the native extensions of the other `xord/*` gems.
- **Ruby helpers** (`lib/xot/`) — small meta-programming mixins (`Hookable`, `Inspectable`, accessor builders, ...), bit-flag utilities, and shared Rake / test scaffolding used by our gems.

Xot exists primarily to keep these patterns consistent across our own projects. It is not designed as a general-purpose dependency, and its API is not promised to be stable for outside use. You are welcome to read and learn from it, but pin a specific version if you depend on it directly.

## 📋 Requirements

- Ruby **3.0.0** or later
- A C++ compiler with C++20 support (Clang on macOS / iOS, GCC or MSVC on Linux / Windows)
- [Rake](https://rubygems.org/gems/rake) and [test-unit](https://rubygems.org/gems/test-unit) (development only)

## 📦 Installation

Add this line to your Gemfile:
```ruby
gem 'xot'
```

Then install:
```bash
$ bundle install
```

Or install it directly:
```bash
$ gem install xot
```

When installed via `gem install`, the C++ headers under `include/xot/` are placed inside the gem directory so that other `xord/*` extensions can locate them at build time (via `Xot::Extension.inc_dir`).

## 📚 What's Included

### C++ headers (`include/xot/`)

| Header           | Provides                                                                 |
| ---------------- | ------------------------------------------------------------------------ |
| `defs.h`         | Type aliases (`uint`, `ushort`, `ulong`, `schar`, `longlong`, ...)       |
| `noncopyable.h`  | `Xot::NonCopyable` — base class that disables copy and assignment        |
| `ref.h`          | `Xot::RefCountable<>` and `Xot::Ref<T>` — intrusive reference counting   |
| `pimpl.h`        | `Xot::PImpl<T>` / `Xot::PSharedImpl<T>` — pimpl idiom on top of smart ptrs |
| `string.h`       | `Xot::String` (extends `std::string`), `stringf`, `split`, `to_s`         |
| `time.h`         | `Xot::time()` (seconds since epoch, double), `Xot::sleep(seconds)`        |
| `exception.h`    | `XotError` hierarchy and `xot_error` / `argument_error` / ... throw helpers |
| `debug.h`        | `Xot::dout` / `doutln` — printf-style debug output (no-op in release)     |
| `util.h`         | Bit / flag helpers, `random`, `deg2rad`, `rad2deg`, memory-usage hints   |
| `windows.h`      | Win32 helpers used by other libraries                                    |

### Ruby modules (`lib/xot/`)

| Module / class              | Purpose                                                                 |
| --------------------------- | ----------------------------------------------------------------------- |
| `Xot::Hookable`             | Attach `on_*` hook methods, or `before` / `after` wrappers around an existing method, on a single object |
| `Xot::Inspectable`          | Compact default `inspect` (class + object_id only) — safe under circular references |
| `Xot::BitFlag`              | Build symbolic bit-flag sets and convert between symbols and bitmasks   |
| `Xot::BitFlagAccessor`      | Class-level accessor generator backed by a `BitFlag`                    |
| `Xot::BitUtil`              | Bit manipulation helpers (`bit(n)`, etc.)                               |
| `Xot::BlockUtil`            | `instance_eval`-or-block-call dispatching                               |
| `Xot::ConstSymbolAccessor`  | Define accessors that translate symbols to module constants             |
| `Xot::UniversalAccessor`    | Single-method getter / setter (`obj.x` reads, `obj.x value` writes)     |
| `Xot::Setter`               | Bulk attribute setter mixin                                             |
| `Xot::Invoker`              | Helper for invoking methods / blocks safely                             |
| `Xot::Util`                 | Misc Ruby utilities                                                     |
| `Xot::Extension`            | Path / name / version helpers used by every `xord/*` gem's build script |
| `Xot::Rake`                 | Rake DSL (`default_tasks`, `build_native_library`, `build_ruby_extension`, `test_ruby_extension`, `build_ruby_gem`, ...) |
| `Xot::Test`                 | Test-unit helpers                                                       |

## 💡 Usage

### C++ — reference counting

```cpp
#include <xot/ref.h>

class Thing : public Xot::RefCountable<>
{
    protected:
        ~Thing () = default;   // destructor is protected; Ref<> handles deletion
};

Xot::Ref<Thing> a = new Thing;   // refcount = 1
{
    Xot::Ref<Thing> b = a;       // refcount = 2
}                                // refcount = 1
// when `a` goes out of scope, refcount = 0 and the object is deleted
```

### C++ — pimpl

```cpp
#include <xot/pimpl.h>

// in the header
class Widget
{
    public:
        Widget ();
        int value () const;
    private:
        struct Data;
        Xot::PImpl<Data> self;
};

// in the .cpp
struct Widget::Data { int n = 42; };
Widget::Widget () {}
int Widget::value () const { return self->n; }
```

### Ruby — `BitFlag`

```ruby
require 'xot/bit_flag'

flags = Xot::BitFlag.new(read: 0x1, write: 0x2, exec: 0x4)
mask  = flags.symbols2bits(:read, :exec)   # => 5
flags.bits2symbols(mask)                   # => [:read, :exec]
```

### Ruby — `Hookable`

```ruby
require 'xot/hookable'

class Greeter
  include Xot::Hookable
  def greet(name) = "hello, #{name}"
end

g = Greeter.new
g.before(:greet) {|name| puts "about to greet #{name}" }
g.greet 'world'
# => about to greet world
# => "hello, world"

# `on` creates a brand-new on_* method instead of wrapping an existing one
g.on(:click) {|x, y| puts "clicked at #{x}, #{y}" }
g.on_click 1, 2
```

### Ruby — `UniversalAccessor`

```ruby
require 'xot/universal_accessor'

class Box
  attr_accessor :width
  universal_accessor :width
end

box = Box.new
box.width 10    # writes
box.width       # => 10 (reads)
```

## 🛠️ Development

Xot uses a shared Rakefile pattern. From the gem root:

```bash
$ rake lib    # build the native C++ library (libxot)
$ rake ext    # build the Ruby C extension
$ rake test   # run the test suite (test/test_*.rb)
$ rake       # default: builds the extension
```

In the [`xord/all`](https://github.com/xord/all) monorepo you can also scope by module, e.g. `rake xot test`.

## 📜 License

**Xot** is licensed under the MIT License.
See the [LICENSE](./LICENSE) file for details.
