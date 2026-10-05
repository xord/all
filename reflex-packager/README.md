# Reflex Packager - Package Reflex apps as native macOS bundles

![License](https://img.shields.io/github/license/xord/reflex-packager)
![Gem Version](https://badge.fury.io/rb/reflex-packager.svg)

## :warning:  Notice

This repository is a read-only mirror of our monorepo.
We do not accept pull requests or direct contributions here.

### :repeat: Where to Contribute?

All development happens in our [xord/all](https://github.com/xord/all) monorepo, which contains all our main libraries.
If you'd like to contribute, please submit your changes there.

For more details, check out our [Contribution Guidelines](./CONTRIBUTING.md).

## :rocket: About

**Reflex Packager** is a CLI tool that packages [Reflex](https://github.com/xord/reflex) applications as native macOS `.app` bundles. It generates an Xcode project that compiles Reflex from the sources of its installed gems together with [CRuby](https://github.com/xord/cruby), and builds a self-contained application that embeds the Ruby runtime.

The packager is runtime-agnostic — each gem (Reflex, [RubySketch](https://github.com/xord/rubysketch), ...) supplies its own profile and reuses this packager as the engine.

## :clipboard: Requirements

- Ruby **3.0.0** or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Xcode (with command line tools)
- The dependent gems are installed automatically: `xot`, `rucy`, `rays`, `reflexion`

## :package: Installation

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

## :bulb: Usage

### Create a new project

```bash
$ reflex new myapp
$ cd myapp
$ ruby main.rb          # run the application directly
```

This generates a project directory with `main.rb` and `reflex.yml`.

### Package as a macOS app

```bash
$ cd myapp
$ reflex package .
```

The built `.app` bundle is placed in `dist/`.

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

  --platform PLATFORM   target platform (default: the one it runs on)
  --config PATH         config file path (default: DIR/reflex.yml)
  --generate-only       generate project files but do not build
  --verbose             verbose output
```

## :gear: Configuration

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
| `macos.cruby` | the packager's | CRuby version, or a path to a cruby checkout |
| `macos.codesign.identity` | `-` | Code signing identity |
| `macos.codesign.team_id` | none | Development team ID |

### CRuby

By default the packager clones the [cruby](https://github.com/xord/cruby) repository at the tag of its CRuby version into `.build/macos/cruby/<version>`, and downloads the prebuilt CRuby there. To use a local checkout instead, set its path as `macos.cruby` in the config, or via the `CRUBY_PATH` environment variable, which overrides the config:

```bash
$ export CRUBY_PATH=/path/to/cruby
$ reflex package .
```

The libraries (xot, rucy, rays, reflex, ...) are compiled from the gems installed for the Ruby running the packager. To package with local checkouts of them, put their `lib` directories on `RUBYLIB`.

## :wrench: How it works

1. Copies application files into a build directory
2. Fetches CRuby unless it is there already
3. Generates an Xcode project (via XcodeGen) with the sources the Rakefiles of the libraries build
4. Builds the `.app` bundle with `xcodebuild`
5. Copies the result to `dist/`

The generated native wrapper embeds CRuby, registers the Reflex extensions, and runs the application's `main.rb` at launch.

## :hammer_and_wrench: Development

```bash
$ rake test         # run the test suite
$ rake              # default task
$ rake example      # package examples/hello with the libraries in this repository
```

`rake example` takes `name=` to package another app under `examples/`, and `platform=` to package for another platform.

In the [`xord/all`](https://github.com/xord/all) monorepo you can scope by module.

## :scroll: License

**Reflex Packager** is licensed under the MIT License.
See the [LICENSE](./LICENSE) file for details.
