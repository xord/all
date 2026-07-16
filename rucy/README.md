<h1 align="center">Rucy</h1>

<p align="center">
  <b>A thin C++ layer on top of Ruby's C API — write Ruby extensions without the boilerplate</b>
</p>

<p align="center">
  <a href="https://deepwiki.com/xord/rucy"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
  <img src="https://img.shields.io/github/license/xord/rucy" alt="License">
  <img src="https://github.com/xord/rucy/actions/workflows/test.yml/badge.svg" alt="Build Status">
  <img src="https://badge.fury.io/rb/rucy.svg" alt="Gem Version">
</p>

<p align="center">
  <a href="#-installation">Installation</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-whats-included">What's Included</a> •
  <a href="#%EF%B8%8F-development">Development</a> •
  <a href="#-license">License</a>
</p>

---

> [!IMPORTANT]
> **This repository is a read-only mirror.** All development happens in the
> [xord/all](https://github.com/xord/all) monorepo — please open issues and
> pull requests there, not here.
> See the [Contribution Guidelines](./CONTRIBUTING.md) for details.

## ✨ Features

- **`Rucy::Value`** — wraps `VALUE` with type predicates, conversions, and method calls
- **Exception-safe method definitions** — `RUCY_DEF0` ... `RUCY_DEFN` macros translate anything you throw in C++ into the corresponding Ruby exception
- **Class and module wrappers** — `define_module`, `define_class`, `define_method`, `define_alloc_func`, and friends
- **One-line type conversion** — macro-generated `Rucy::value(...)` / `Rucy::value_to<T>(...)` overloads move data between Ruby and native classes
- **Call Ruby from C++** — `call`, `eval`, and `protect` invoke Ruby code with C++ exception safety
- **Build helpers and tooling** — `Rucy::Extension`, `Rucy::Rake`, and the `rucy2rdoc` doc extractor

**Rucy** reduces the boilerplate involved in writing a Ruby extension in C++. It is used by the native extensions in the `xord/*` family — [Beeps](https://github.com/xord/beeps), [Rays](https://github.com/xord/rays), and [Reflex](https://github.com/xord/reflex) — and depends on [Xot](https://github.com/xord/xot) for low-level utilities such as reference counting, the pimpl idiom, and the string / exception classes.

> [!NOTE]
> Like Xot, Rucy exists primarily for our own gems. The API is stable enough for us to build on, but it is not a general-purpose extension framework — feel free to read it and learn from it, but pin a specific version if you depend on it directly.

## 📦 Installation

Add this line to your Gemfile:
```ruby
gem 'rucy'
```

Then install:
```bash
$ bundle install
```

Or install it directly:
```bash
$ gem install rucy
```

When linking against Rucy from your own extension, point `extconf.rb` at the gem's `include/` and `lib/` directories — `Rucy::Extension.inc_dir` and `Rucy::Extension.lib_dir` return the right paths.

### Requirements

- Ruby **3.0.0** or later
- A C++ compiler with C++20 support
- [Xot](https://rubygems.org/gems/xot) (declared as a runtime dependency)
- Rake and test-unit (development only)

## 🚀 Quick Start

A minimal extension — one C++ file, one `extconf.rb`, and you can call it from Ruby:

```cpp
// ext/hello/hello.cpp
#include <rucy/rucy.h>
#include <rucy/extension.h>

using namespace Rucy;

/*
  Returns a friendly greeting.
*/
RUCY_DEF1(greet, name)
{
    return value(Xot::String("hello, ") + name.c_str());
}
RUCY_DEF_END

extern "C" void
Init_hello ()
{
    RUCY_TRY

    Module mHello = define_module("Hello");
    mHello.define_module_function("greet", greet);

    RUCY_CATCH
}
```

```ruby
# ext/hello/extconf.rb
require 'rucy/extension'
require 'mkmf'

$INCFLAGS << " -I#{Xot::Extension.inc_dir} -I#{Rucy::Extension.inc_dir}"
$LDFLAGS  << " -L#{Xot::Extension.lib_dir} -L#{Rucy::Extension.lib_dir} -lxot -lrucy"

create_makefile 'hello/hello'
```

```ruby
# Use it from Ruby
require 'hello/hello'
Hello.greet 'world'   # => "hello, world"
```

## 💡 Examples

### Exception-safe method bodies

Anything you throw inside a `RUCY_DEF*` body — `Rucy::RubyException`, `std::exception`, `Xot::XotError`, or even a `const char*` — is caught by `RUCY_DEF_END` and re-raised as the corresponding Ruby exception. You can also raise directly:

```cpp
RUCY_DEF1(divide, n)
{
    if (n.as_i() == 0)
        argument_error(__FILE__, __LINE__, "divide by zero");
    return value(100 / n.as_i());
}
RUCY_DEF_END
```

### Calling Ruby from C++

```cpp
Value ary = eval("[1, 2, 3]");
Value n   = ary.call("sum");    // => Value(6)
```

For more examples, see `ext/rucy/tester.cpp` (used by the test suite) and the native extensions in [Beeps](https://github.com/xord/beeps), [Rays](https://github.com/xord/rays), and [Reflex](https://github.com/xord/reflex).

## 📚 What's Included

### C++ headers (`include/rucy/`)

| Header        | Provides                                                                                 |
| ------------- | ---------------------------------------------------------------------------------------- |
| `rucy.h`      | `Rucy::init()`, the `Rucy` module, and the error class hierarchy                         |
| `ruby.h`      | A safe `<ruby.h>` wrapper plus the `RubyValue` / `RubySymbol` typedefs                   |
| `value.h`     | `Rucy::Value` — wraps `VALUE` with type predicates, conversions, and method calls        |
| `module.h`    | `Rucy::Module` — `define_module`, `define_class`, `define_method`, ...                   |
| `class.h`     | `Rucy::Class` — adds `define_alloc_func` on top of `Module`                              |
| `function.h`  | `Rucy::call("method", ...)`, `eval`, `protect` — invoke Ruby code with C++ exception safety |
| `symbol.h`    | `Rucy::Symbol` plus the `RUCY_SYM`, `RUCY_SYM_Q`, `RUCY_SYM_B` macros                    |
| `exception.h` | `RubyException`, `RubyJumpTag`, and `raise` / `*_error` throw helpers                    |
| `extension.h` | Method definition macros (`RUCY_DEF0` ... `RUCY_DEFN`) and `VALUE` ↔ native converters   |

### Method definition macros

| Macro                        | Purpose                                                                 |
| ---------------------------- | ----------------------------------------------------------------------- |
| `RUCY_DEF0` ... `RUCY_DEF12` | Define a Ruby method that takes 0–12 arguments                          |
| `RUCY_DEFN`                  | Define a variadic Ruby method (`int argc, const Value* argv`)           |
| `RUCY_DEF_ALLOC`             | Define an allocator function for a class                                |
| `RUCY_DEF_END`               | Close a method definition; converts C++ exceptions into Ruby exceptions |
| `RUCY_TRY` / `RUCY_CATCH`    | Wrap any block of C++ code in Ruby-safe exception translation           |

### Type conversion macros

`RUCY_DECLARE_VALUE_FROM_TO` / `RUCY_DEFINE_VALUE_FROM_TO` (and the `WRAPPER` / `ARRAY` variants) generate `Rucy::value(...)` and `Rucy::value_to<T>(...)` overloads so you can move data between Ruby and a native class with one line of declaration plus one line of definition.

### Ruby side (`lib/rucy/`)

| Module            | Purpose                                                                                         |
| ----------------- | ----------------------------------------------------------------------------------------------- |
| `Rucy::Extension` | Path / name / version helpers, mirroring `Xot::Extension` for Rucy-based gems                   |
| `Rucy::Rake`      | Rake DSL extensions used by `xord/*` gems (`build_native_library`, `build_ruby_extension`, ...) |

### Tools (`bin/`)

| Tool        | Purpose                                                                               |
| ----------- | ------------------------------------------------------------------------------------- |
| `rucy2rdoc` | Extract doc comments from C++ files using `RUCY_DEF*` macros into RDoc-friendly stubs |

## 🧩 Part of the xord family

Rucy sits directly on top of [Xot](https://github.com/xord/xot) and powers the native extensions of every gem above it:

[`xot`](https://github.com/xord/xot) → `rucy` → [`beeps`](https://github.com/xord/beeps) / [`rays`](https://github.com/xord/rays) → [`reflex`](https://github.com/xord/reflex) → [`processing`](https://github.com/xord/processing) → [`rubysketch`](https://github.com/xord/rubysketch) → [`reight`](https://github.com/xord/reight)

## 🛠️ Development

```bash
$ rake lib    # build the native C++ library (librucy)
$ rake ext    # build the test extension
$ rake test   # run the test suite
$ rake doc    # generate RDoc from C++ sources via rucy2rdoc
$ rake       # default: builds the extension
```

Several headers and sources are ERB templates (`*.erb`) expanded automatically at build time. `NPARAM_MAX = 12` in the Rakefile auto-generates `RUCY_DEF0` ... `RUCY_DEF12` and the matching overloads of `call`, `protect`, and friends.

In the [`xord/all`](https://github.com/xord/all) monorepo you can also scope by module, e.g. `rake rucy test`.

## 📜 License

**Rucy** is licensed under the MIT License.
See the [LICENSE](./LICENSE) file for details.
