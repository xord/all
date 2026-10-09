# Reflex Packager - Package Reflex apps as native macOS and Windows apps

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

**Reflex Packager** is a CLI tool that packages [Reflex](https://github.com/xord/reflex) applications as native apps, which carry the Ruby runtime they run on and run where Ruby is not installed:

- On macOS, a `.app` bundle: it generates an Xcode project that compiles the libraries from the sources of their installed gems together with [CRuby](https://github.com/xord/cruby).
- On Windows, a folder with an `.exe`: it links what the installed gems of the libraries built into an executable, which runs on the Ruby DLL of [RubyInstaller](https://rubyinstaller.org/) shipped beside it.

The packager is runtime-agnostic — each gem (Reflex, [RubySketch](https://github.com/xord/rubysketch), ...) supplies its own profile and reuses this packager as the engine.

## :clipboard: Requirements

- Ruby **3.0.0** or later
- On macOS
  - [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
  - Xcode (with command line tools)
- On Windows
  - [RubyInstaller](https://rubyinstaller.org/) with the MSYS2 DevKit (`ridk install`), which the gems are built with too
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

### Package as an app

```bash
$ cd myapp
$ reflex package .
```

The app is packaged for the platform the packager runs on, as each one builds only on itself, and placed in `dist/`:

- macOS: `dist/<name>.app`
- Windows: `dist/<name>/`, with `<name>.exe`, and the DLLs it loads, the standard library, the libraries, the gems and the app in `lib/`

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
  --pack                put the files of the app together in a data file, for a release
  --verbose             verbose output
```

## :gear: Configuration

The project is configured via `reflex.yml` (or `reflex.yaml`) in the project directory.

```yaml
name: MyApp
bundle_id: com.example.myapp
version: 1.0.0
# build: 1.0.0
# copyright: © 2026 Example
icon: icon.png
# main: main.rb
# files:
#   - "lib/**/*.rb"

# macos:
#   deployment_target: "11.0"
#   archs: [arm64, x86_64]
#   codesign:
#     identity: "-"
#     team_id: XXXXXXXXXX

# windows:
#   console: false

# localizations:
#   ja:
#     name: マイアプリ
```

| Key | Default | Description |
|-----|---------|-------------|
| `name` | directory name | Application name |
| `bundle_id` | `org.xord.reflex.<name>` | macOS bundle identifier |
| `version` | `0.1.0` | Application version |
| `build` | `version` | Build version |
| `copyright` | none | Copyright notice, shown in the About panel on macOS and in the properties of the executable on Windows |
| `main` | `main.rb` | Entry point script |
| `icon` | none | Path to an icon image (PNG) |
| `files` | none | Additional files to bundle (glob patterns) |
| `macos.deployment_target` | `11.0` | Minimum macOS version |
| `macos.archs` | `[arm64, x86_64]` | Target architectures |
| `macos.cruby` | the packager's | CRuby version, or a path to a cruby checkout |
| `macos.codesign.identity` | `-` | Code signing identity |
| `macos.codesign.team_id` | none | Development team ID |
| `windows.console` | `false` | Keep a console window, which shows what the app prints and the error it dies of |
| `localizations` | none | `name` and `copyright` in other languages than English |

### Versions

`version` is the version to show, and `build` the one to tell builds apart with. Both are numbers separated by dots:

| | Shown (`CFBundleShortVersionString`, `ProductVersion`) | Build (`CFBundleVersion`, `FileVersion`) |
|-----|-----|-----|
| `version: 1.2.3` | `1.2.3` | `1.2.3` |
| `version: 1.2.3.4` | `1.2.3` | `1.2.3.4` |
| `version: 1.2.3` and `build: 456` | `1.2.3` | `456` |

A fourth number of `version` tells a build apart from another of the same version, as one uploaded again for a review. On Windows, each number has to be 65535 or less. Quote a version or a build of two numbers, as `'1.10'`, which YAML reads as the number 1.1 otherwise.

### Localizations

`name` and `copyright` are in English, and `localizations` has them in other languages, by language tags as `ja` and `zh-Hans`; what a language leaves out is the English one:

```yaml
name: My App
copyright: © 2026 Example
localizations:
  ja:
    name: マイアプリ
```

On macOS, the name in the language of the system is shown in the Finder, the Dock, the menu bar and the application menu, and the copyright in the About panel. On Windows, they are in the version resource of the executable, in the languages Windows knows, and the name in the language of the user is the one the app has by default (`Reflex::Application#name`), which a tray shows. The properties of the executable show the English ones, though, and its file name stays as it is.

### Packing for a release

With `--pack`, the Ruby scripts of the app are compiled into instruction sequences and put together in `app/data.bin`, so the package carries none of the scripts. `require`, `require_relative` and `load` read them from the data file. The other files of the app are in `app/` as they are.

The bytes of the data file are substituted with others, which keeps the scripts from being read as they are, though it is no encryption.

The scripts are compiled by the Ruby the package runs them on: on Windows, the one running the packager, and on macOS, the CRuby in the app. On macOS, the app is built and run once to compile them, then built again, so a packed app has to be built, not only generated.

### CRuby

By default the packager clones the [cruby](https://github.com/xord/cruby) repository at the tag of its CRuby version into `.build/macos/cruby/<version>`, and downloads the prebuilt CRuby there. To use a local checkout instead, set its path as `macos.cruby` in the config, or via the `CRUBY_PATH` environment variable, which overrides the config:

```bash
$ export CRUBY_PATH=/path/to/cruby
$ reflex package .
```

### Libraries

The libraries the app runs on (xot, rucy, rays, reflex, ...) are the gems with `lib/<name>/extension.rb` the gemspec of the profile depends on, taken from the gems installed for the Ruby running the packager: macOS compiles their sources, and Windows links what their gem builds left. To package with local checkouts of them, put their `lib` directories on `RUBYLIB`.

### Gems

The gems in the default group of the `Gemfile` of the app are shipped with it, with what they depend on, and `require 'bundler/setup'` does nothing in the package.

- A library in the `Gemfile`, as `rays-video`, is built in or linked as the ones of the profile.
- On macOS, a gem with a native extension is refused, as the extension is built for the Ruby running the packager rather than for CRuby.
- On Windows, the standard gems which were default gems once, as `csv` and `fiddle`, are shipped too; CRuby has them in its standard library on macOS.

## :wrench: How it works

On macOS:

1. Copies the application files, the libraries and the gems into a build directory
2. Fetches CRuby unless it is there already
3. Generates an Xcode project (via XcodeGen) with the sources the Rakefiles of the libraries build
4. Builds the `.app` bundle with `xcodebuild`
5. Copies the result to `dist/`

On Windows:

1. Copies the application files, the libraries and the gems into a build directory
2. Compiles the executable and links the extensions and the archives the gem builds of the libraries left into it, with the Ruby DLL
3. Copies the executable, the DLLs it loads, found through their import tables, and the standard library to `dist/`

The executable registers the extensions of the libraries and runs `boot.rb`, which loads the application's `main.rb` and shows an error it dies of with `Reflex.alert`, unless a terminal or a console shows it.

## :hammer_and_wrench: Development

```bash
$ rake test         # run the test suite
$ rake              # default task
$ rake example      # package examples/hello with the libraries in this repository
```

`rake example` takes `name=` to package another app under `examples/`, `platform=` to package for another platform, and `pack=1` to package with `--pack`.

In the [`xord/all`](https://github.com/xord/all) monorepo you can scope by module.

## :scroll: License

**Reflex Packager** is licensed under the MIT License.
See the [LICENSE](./LICENSE) file for details.
