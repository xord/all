<h1 align="center">CRuby</h1>

<p align="center">
  <b>Embed the CRuby (MRI) interpreter in macOS / iOS apps</b>
</p>

<p align="center">
  <a href="https://deepwiki.com/xord/cruby"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
  <img src="https://img.shields.io/github/license/xord/cruby" alt="License">
  <img src="https://github.com/xord/cruby/workflows/Build/badge.svg" alt="Build">
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

- **Full CRuby (MRI) runtime** — embeds the standard interpreter into a macOS or iOS application
- **Self-contained `xcframework`** — builds Ruby from source (along with OpenSSL and libyaml) into a framework you drop into your Xcode project
- **Small Objective-C API** — evaluate Ruby code, call methods on Ruby objects, and bridge values between Objective-C and Ruby
- **Safe error handling** — every method that may raise from Ruby has a paired `rescue:` variant
- **YJIT support** — turn on YJIT before booting the interpreter
- **Extensible** — register bundled Ruby libraries and statically-linked C extensions

**CRuby** is the runtime that lets the `xord/*` family — [Reflex](https://github.com/xord/reflex), [Processing](https://github.com/xord/processing), [RubySketch](https://github.com/xord/rubysketch), and [Reight](https://github.com/xord/reight) — ship as native macOS / iOS apps.

> [!IMPORTANT]
> Not a Ruby gem. This module is distributed exclusively via **CocoaPods**.

## 📦 Installation

Add `CRuby` to your `Podfile`:

```ruby
platform :ios, '10.0'    # or: platform :osx, '10.7'
pod 'CRuby', git: 'https://github.com/xord/cruby'
```

Then run:

```bash
$ CRUBY_OS=ios pod install --verbose
# or for macOS:
$ CRUBY_OS=macos pod install --verbose
```

> [!TIP]
> The `--verbose` flag is recommended — the framework is built from source the first time and that takes a while.

The pod's `prepare_command` runs `rake download_or_build`, which by default downloads a prebuilt archive from GitHub Releases when available and falls back to building locally otherwise. To force a local build:

```bash
$ rake build os=ios noprebuilt=1
```

To use a custom prebuilt archive:

```bash
$ rake download_or_build prebuilt=/path/to/archive.tar.gz
```

### Requirements

- **macOS** 10.7 or later
- **iOS** 10.0 or later
- Xcode (recent enough to build the deployment targets above)
- [CocoaPods](https://cocoapods.org/)
- Ruby and `rake` (used to build the framework from source)

The build vendors and statically links the following from upstream tarballs:

| Library                                           | Role                                                |
| ------------------------------------------------- | --------------------------------------------------- |
| [Ruby](https://www.ruby-lang.org/)                | The interpreter itself                              |
| [OpenSSL](https://www.openssl.org/)               | TLS / crypto support for stdlib `openssl`           |
| [libyaml](https://pyyaml.org/wiki/LibYAML)        | YAML support for stdlib `psych`                     |

The exact versions are pinned in [`config.rb`](./config.rb) (`RUBY_URL`, `OSSL_URL`, `YAML_URL`).

## 🚀 Quick Start

Evaluate a Ruby snippet:

```objc
#import <CRuby.h>

CRBValue *result = [CRuby evaluate:@"[1, 2, 3].map {|n| n ** 2}"];
NSLog(@"result: %@", result.inspect);   // result: [1, 4, 9]
```

## 💡 Examples

### Boot a Ruby entry point and call into it

```objc
[CRuby start:@"main.rb" rescue:^(CRBValue *e) {
    NSLog(@"ruby error: %@", e.inspect);
}];

CRBValue *greeter = [CRuby evaluate:@"Greeter.new"];
CRBValue *hello   = [greeter call:@"hello"
                             arg1:[CRBValue valueWithNSString:@"world"]];
NSLog(@"%@", hello.toString);
```

### Enable YJIT

```objc
[CRuby enableYJIT];   // must be called before +start: / +evaluate:
[CRuby start:@"main.rb"];
```

### Bundle a stdlib subset or a gem with your app

```objc
[CRuby addLibrary:@"my_lib" bundle:[NSBundle mainBundle]];
[CRuby evaluate:@"require 'my_lib/something'"];
```

### Register a statically-linked C extension

```objc
extern void Init_my_ext();
[CRuby addExtension:@"my_ext" init:^{ Init_my_ext(); }];
```

## 📚 What's Included

The pod exposes two Objective-C classes.

### `CRuby` — the interpreter

```objc
@interface CRuby : NSObject

+ (BOOL)start:(NSString*)filename;
+ (BOOL)start:(NSString*)filename rescue:(RescueBlock)rescue;

+ (BOOL)load:(NSString*)filename;
+ (BOOL)load:(NSString*)filename rescue:(RescueBlock)rescue;

+ (CRBValue*)evaluate:(NSString*)string;
+ (CRBValue*)evaluate:(NSString*)string rescue:(RescueBlock)rescue;

+ (void)addLibrary:(NSString*)name bundle:(NSBundle*)bundle;
+ (void)addExtension:(NSString*)path init:(void(^)())init;

+ (void)enableYJIT;

@end
```

| Method                | Purpose                                                                       |
| --------------------- | ----------------------------------------------------------------------------- |
| `+start:`             | Boot the interpreter (once) and run the given Ruby file as the entry point   |
| `+load:`              | `require`-style loading of an additional Ruby file                            |
| `+evaluate:`          | Evaluate a Ruby source string; returns a `CRBValue`                           |
| `+addLibrary:bundle:` | Register an extra `.bundle` resource directory as a Ruby load path            |
| `+addExtension:init:` | Register a statically-linked C extension and its `Init_*` function            |
| `+enableYJIT`         | Turn on YJIT before booting the interpreter                                   |

All methods that may raise from Ruby have a paired `rescue:` variant that takes a `^(CRBValue* exception)` block instead of crashing.

### `CRBValue` — Ruby value wrapper

`CRBValue` wraps a Ruby `VALUE`. It can be constructed from an `NSString` or directly from a `VALUE`, queried for its type, converted to native Objective-C types, and used to call Ruby methods.

```objc
@interface CRBValue : NSObject

@property (nonatomic, readonly) VALUE value;

+ (instancetype)valueWithVALUE:(VALUE)value;
+ (instancetype)valueWithNSString:(NSString*)string;

- (CRBValue*)call:(NSString*)method;
- (CRBValue*)call:(NSString*)method arg1:(CRBValue*)arg1;
- (CRBValue*)call:(NSString*)method arg1:(CRBValue*)arg1 arg2:(CRBValue*)arg2;
- (CRBValue*)call:(NSString*)method arg1:(CRBValue*)arg1 arg2:(CRBValue*)arg2 arg3:(CRBValue*)arg3;
- (CRBValue*)call:(NSString*)method args:(NSArray*)values;

- (BOOL)isNil;
- (BOOL)isInteger;
- (BOOL)isFloat;
- (BOOL)isString;
- (BOOL)isArray;
- (BOOL)isDictionary;

- (BOOL)toBOOL;
- (NSInteger)toInteger;
- (double)toFloat;
- (NSString*)toString;
- (NSArray<CRBValue*>*)toArray;
- (NSDictionary<CRBValue*, CRBValue*>*)toDictionary;

- (NSString*)inspect;

@end
```

Each `call:` overload also has a `rescue:` variant.

## 🧩 Part of the xord family

CRuby is the native runtime underneath the `xord/*` app stack — it is consumed as a CocoaPod by apps built with [Reflex](https://github.com/xord/reflex), [Processing](https://github.com/xord/processing), [RubySketch](https://github.com/xord/rubysketch), and [Reight](https://github.com/xord/reight), and fetched automatically by [reflex-packager](https://github.com/xord/reflex-packager).

## 🛠️ Development

Run from the `cruby/` directory:

```bash
$ rake                       # default: build
$ rake build os=ios          # build only for iOS (device + simulator)
$ rake build os=macos        # build only for macOS
$ rake build targets="macosx:x86_64, iphoneos:arm64"   # narrower target list
$ rake test                  # run the test suite
$ rake archive               # produce the distributable archive
$ rake clean                 # remove build outputs
```

Useful switches (passed as environment-style arguments):

| Switch                    | Effect                                                                  |
| ------------------------- | ----------------------------------------------------------------------- |
| `os=ios` / `os=macos`     | Build only for the named OS family                                      |
| `targets="..."`           | Build only the specified `<sdk>:<arch>` combinations                    |
| `prebuilt=/path/to.tgz`   | Use a user-supplied prebuilt archive instead of downloading             |
| `noprebuilt=1`            | Always build from source (ignore prebuilt archive)                      |
| `yjit_stats=1`            | Pass `--yjit-stats` when configuring the interpreter                    |

In the [`xord/all`](https://github.com/xord/all) monorepo you can scope by module, e.g. `rake cruby build`.

## 📜 License

**CRuby (xord/cruby)** is licensed under the MIT License.
See the [LICENSE](./LICENSE) file for details.

The bundled upstream sources retain their own licenses (Ruby: BSD-2-clause / Ruby License; OpenSSL: Apache-2.0; libyaml: MIT).
