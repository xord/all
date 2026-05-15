# Rucy - A Ruby C++ extension helper library

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/xord/rucy)
![License](https://img.shields.io/github/license/xord/rucy)
![Build Status](https://github.com/xord/rucy/actions/workflows/test.yml/badge.svg)
![Gem Version](https://badge.fury.io/rb/rucy.svg)

## ⚠️  Notice

This repository is a read-only mirror of our monorepo.
We do not accept pull requests or direct contributions here.

### 🔄 Where to Contribute?

All development happens in our [xord/all](https://github.com/xord/all) monorepo, which contains all our main libraries.
If you'd like to contribute, please submit your changes there.

For more details, check out our [Contribution Guidelines](./CONTRIBUTING.md).

Thanks for your support! 🙌

## 🚀 About

**Rucy** is a thin C++ layer on top of Ruby's C API. It reduces the boilerplate involved in writing a Ruby extension in C++ by wrapping `VALUE`, providing exception-safe method definitions, and converting between native types and Ruby values.

It is used by the native extensions in the `xord/*` family — [Beeps](https://github.com/xord/beeps), [Rays](https://github.com/xord/rays), and [Reflex](https://github.com/xord/reflex). It depends on [Xot](https://github.com/xord/xot) for low-level utilities such as reference counting, the pimpl idiom, and the string / exception classes.

Like Xot, Rucy exists primarily for our own gems. The API is stable enough for us to build on, but it is not a general-purpose extension framework — feel free to read it and learn from it, but pin a specific version if you depend on it directly.

## 📋 Requirements

- Ruby **3.0.0** or later
- A C++ compiler with C++20 support
- [Xot](https://rubygems.org/gems/xot) (declared as a runtime dependency)
- Rake and test-unit (development only)

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

## 💡 Usage

### A minimal extension

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

## 🛠️ Development

```bash
$ rake lib    # build the native C++ library (librucy)
$ rake ext    # build the test extension
$ rake test   # run the test suite
$ rake doc    # generate RDoc from C++ sources via rucy2rdoc
$ rake       # default: builds the extension
```

Several headers and sources are ERB templates (`*.erb`) expanded automatically at build time. `NPARAM_MAX = 12` in the Rakefile auto-generates `RUCY_DEF0` ... `RUCY_DEF12` and the matching overloads of `call`, `protect`, and friends.

## 📜 License

**Rucy** is licensed under the MIT License.
See the [LICENSE](./LICENSE) file for details.
