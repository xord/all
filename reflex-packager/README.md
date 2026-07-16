<h1 align="center">Reflex Packager</h1>

<p align="center">
  <b>Package Reflex apps as native macOS bundles</b>
</p>

<p align="center">
  <img src="https://img.shields.io/github/license/xord/reflex-packager" alt="License">
  <img src="https://badge.fury.io/rb/reflex-packager.svg" alt="Gem Version">
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

- **Native `.app` bundles** — packages [Reflex](https://github.com/xord/reflex) applications as self-contained macOS apps
- **Xcode project generation** — generates an Xcode project and Podfile for you (via XcodeGen)
- **Embedded Ruby runtime** — fetches [CRuby](https://github.com/xord/cruby) and Reflex via CocoaPods and embeds the interpreter in the app
- **Simple CLI** — `reflex new` scaffolds a project, `reflex package` builds the bundle
- **Declarative configuration** — app name, bundle id, icon, code signing, and more via `reflex.yml`
- **Runtime-agnostic** — each gem (Reflex, [RubySketch](https://github.com/xord/rubysketch), ...) supplies its own profile and reuses this packager as the engine

## 📦 Installation

Add this line to your Gemfile:
```ruby
gem 'reflex-packager'
```

Then install:
```bash
$ bundle install
```

Or install it directly:
```bash
$ gem install reflex-packager
```

### Requirements

- Ruby **3.0.0** or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- [CocoaPods](https://cocoapods.org/) (`brew install cocoapods`)
- Xcode (with command line tools)
- The dependent gems are installed automatically: `xot`, `rucy`, `rays`, `reflexion`

## 🚀 Quick Start

Create a new project and package it as a macOS app:

```bash
$ reflex new myapp
$ cd myapp
$ ruby main.rb          # run the application directly
$ reflex package .
```

`reflex new` generates a project directory with `main.rb` and `reflex.yml`; `reflex package` places the built `.app` bundle in `dist/`.

## 📚 What's Included

### CLI options

```
Usage: reflex <command> [options]

Commands:
  new NAME       create a new application project
  package [DIR]  package the application in DIR (default: .) as an app

Options:
  -h, --help     show this message
  --version      show version
```

Package command options:

```
reflex package [options] [DIR]

  --platform PLATFORM   target platform (default: macos)
  --config PATH         config file path (default: DIR/reflex.yml)
  --generate-only       generate project files but do not build
  --verbose             verbose output
```

### Configuration

The project is configured via `reflex.yml` (or `reflex.yaml`) in the project directory.

```yaml
name: MyApp
bundle_id: com.example.myapp
version: 1.0.0
icon: icon.png
# main: main.rb
# files:
#   - "lib/**/*.rb"

# macos:
#   deployment_target: "11.0"
#   archs: arm64
#   codesign:
#     identity: "-"
#     team_id: XXXXXXXXXX

# pods:
#   cruby:
#     path: /path/to/cruby
#   reflex:
#     path: /path/to/reflex
```

| Key | Default | Description |
|-----|---------|-------------|
| `name` | directory name | Application name |
| `bundle_id` | `org.xord.reflex.<name>` | macOS bundle identifier |
| `version` | `0.1.0` | Application version |
| `main` | `main.rb` | Entry point script |
| `icon` | none | Path to an icon image (PNG) |
| `files` | none | Additional files to bundle (glob patterns) |
| `macos.deployment_target` | `11.0` | Minimum macOS version |
| `macos.archs` | `arm64` | Target architectures |
| `macos.codesign.identity` | `-` | Code signing identity |
| `macos.codesign.team_id` | none | Development team ID |

### Pod overrides

By default the packager fetches CRuby and Reflex pods from their git repositories. To use local checkouts instead, set paths in the config or via the `REFLEX_PODS_PATH` environment variable:

```bash
$ export REFLEX_PODS_PATH=/path/to/pods
$ reflex package .
```

## 🔧 How it works

1. Copies application files into a build directory
2. Generates an Xcode project (via XcodeGen) and a Podfile
3. Runs `pod install` to fetch CRuby and Reflex pods
4. Builds the `.app` bundle with `xcodebuild`
5. Copies the result to `dist/`

The generated native wrapper embeds CRuby, registers the Reflex extensions, and runs the application's `main.rb` at launch.

## 🧩 Part of the xord family

Reflex Packager is the deployment layer of the `xord/*` stack: it ships apps built on [`reflex`](https://github.com/xord/reflex) (and, via profiles, gems like [`rubysketch`](https://github.com/xord/rubysketch)) by embedding the [`cruby`](https://github.com/xord/cruby) runtime, and pulls in `xot`, `rucy`, `rays`, and `reflexion` as dependencies.

## 🛠️ Development

```bash
$ rake test         # run the test suite
$ rake              # default task
```

In the [`xord/all`](https://github.com/xord/all) monorepo you can scope by module.

## 📜 License

**Reflex Packager** is licensed under the MIT License.
See the [LICENSE](./LICENSE) file for details.
