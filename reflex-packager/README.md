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

- macOS: `dist/generic/<app name>.app` signed with Developer ID, or `dist/adhoc/<app name>.app` signed otherwise, only to be run where it is built, and `dist/appstore/<name>-<version>.pkg` for the Mac App Store
- Windows: `dist/generic/<name>/`, with `<name>.exe`, and the DLLs it loads, the standard library, the libraries, the gems and the app in `lib/`

The zip of the app is put beside it. `<name>` is the name of the app with no spaces or symbols, as `MyApp`, and `<app name>` is the name as it is, as `My App`, which Finder and the Dock show.

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
  --generic             package the app signed with Developer ID, also with --appstore
  --appstore            package the app for the Mac App Store, only it unless --generic
  --notarize            have Apple check the app with Developer ID, on macos
  --notarize-submit     only submit the app to be notarized, not waiting
  --notarize-wait ID    only wait for the notarization ID, by the API key
  --notarize-export     only wait for the notarization submitted and export the app
  --verbose             verbose output
```

## :gear: Configuration

The project is configured via `reflex.yml` (or `reflex.yaml`) in the project directory.

```yaml
name: MyApp
bundle_id: com.example.myapp
version: 1.0.0
# copyright: © 2026 Example
icon: icon.png
# main: main.rb
# files:
#   - "lib/**/*.rb"

# macos:
#   deployment_target: "11.0"
#   archs: [arm64, x86_64]
#   category: public.app-category.games
#   codesign:
#     identity: "-"
#     team_id: XXXXXXXXXX

# windows:
#   console: false

# upload:
#   itchio:
#     project: user/game

# localizations:
#   ja:
#     name: マイアプリ
```

| Key | Default | Description |
|-----|---------|-------------|
| `name` | directory name | Application name |
| `bundle_id` | `org.xord.reflex.<name>` | macOS bundle identifier |
| `version` | the `VERSION` file, or `0.1.0` | Application version |
| `copyright` | none | Copyright notice, shown in the About panel on macOS and in the properties of the executable on Windows |
| `main` | `main.rb` | Entry point script |
| `icon` | none | Path to an icon image (PNG) |
| `files` | none | Additional files to bundle (glob patterns) |
| `macos.deployment_target` | `11.0` | Minimum macOS version |
| `macos.archs` | `[arm64, x86_64]` | Target architectures |
| `macos.cruby` | the packager's | CRuby version, or a path to a cruby checkout |
| `macos.category` | none | [Category](https://developer.apple.com/documentation/bundleresources/information-property-list/lsapplicationcategorytype) of the app in Info.plist, as `public.app-category.games`, which the App Store requires |
| `macos.codesign.identity` | `-` | Code signing identity, `-` to sign ad hoc, or by the certificate Apple manages with `team_id`, and `Developer ID Application` by the certificate in the keychain; `APPLE_CODESIGN_IDENTITY` overrides it |
| `macos.codesign.team_id` | none | Development team ID; `APPLE_TEAM_ID` overrides it |
| `windows.console` | `false` | Keep a console window, which shows what the app prints and the error it dies of |
| `upload.itchio.project` | none | Project of itch.io to upload the app to, as `user/game` of `https://user.itch.io/game` |
| `localizations` | none | `name` and `copyright` in other languages than English |

### Versions

`version` is the version to show, and the one to tell builds apart with, of numbers separated by dots:

| | Shown (`CFBundleShortVersionString`, `ProductVersion`) | Build (`CFBundleVersion`, `FileVersion`) |
|-----|-----|-----|
| `version: 1.2.3` | `1.2.3` | `1.2.3` |
| `version: 1.2.3.4` | `1.2.3` | `1.2.3.4` |

Without `version`, the version is read from the `VERSION` file in the directory of the app, if there is one, so that the file can be the only place to keep it in, as the gems do.

A fourth number of `version` tells a build apart from another of the same version, but not on macOS, where the build has to be of three numbers at most, as `CFBundleVersion`. On Windows, each number has to be 65535 or less. Quote a version of two numbers, as `'1.10'`, which YAML reads as the number 1.1 otherwise.

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

### Signing and notarizing on macOS

By default, the app is signed ad hoc, which runs on the Mac it is built on, but which macOS warns of when the app is downloaded. To have the app opened with no warning, sign it with Developer ID and have Apple notarize it.

With `team_id` and either of the identities below, the app is archived and exported by `xcodebuild`, signed with Developer ID and the hardened runtime:

- With the identity `-`, by the certificate Apple manages for the team, by the account of Xcode, so no certificate is needed in the keychain
- With the identity `Developer ID Application`, by the certificate in the keychain, as on CI

The certificate can be given by the environment variables too, put into a keychain of its own only while the app is signed, as on CI, and the identity is `Developer ID Application` then:

| Variable | Value |
|-----|-----|
| `APPLE_CODESIGN_P12` | The certificate with its private key, exported from the keychain into a `.p12` file, in base64 |
| `APPLE_CODESIGN_P12_PASSWORD` | Password of the `.p12` file |

Where no account of Xcode is, as on CI, Apple is asked by an API key of App Store Connect, which the environment variables tell:

| Variable | Value |
|-----|-----|
| `APPLE_API_ISSUER_ID` | Issuer ID |
| `APPLE_API_KEY_ID` | Key ID |
| `APPLE_API_KEY_P8` | Content of the private key file, `AuthKey_<ID>.p8` |
| `APPLE_API_KEY_PATH` | Path to the private key file, in place of `APPLE_API_KEY_P8` |

The team ID can be given by `APPLE_TEAM_ID` in place of the config, as the identity by `APPLE_CODESIGN_IDENTITY`, to keep them out of the repository of the app.

With `--notarize`, the app is sent to Apple to be notarized, which takes some minutes, and exported to `dist/generic/` with the ticket of the notarization stapled, which macOS sees with no network:

```bash
$ export APPLE_TEAM_ID=XXXXXXXXXX
$ reflex package --pack --notarize .
```

The notarization can be split into the steps, so as not to keep a Mac waiting, as on CI:

1. `--notarize-submit` builds the app and sends it, printing `Submitted for the notarization: <ID>`; the archive sent is `.build/macos/generic/<name>.xcarchive`
2. `--notarize-wait <ID>` waits for Apple to check the app, by the API key, on any system
3. `--notarize-export` exports the app notarized from the archive, waiting for the notarization if not finished yet, on macOS

`--generic` makes sure the app is signed with Developer ID, failing if not, as with no team.

### Packaging for the Mac App Store

With `--appstore`, the app is archived in the sandbox, which the Mac App Store needs, and exported into `dist/appstore/<name>-<version>.pkg` to upload to App Store Connect, signed by the certificates of the team that Apple manages, as the profile. It needs the team and `macos.category` in the config, and makes only the one for the App Store, unless `--generic` or `--notarize` asks for the generic one too, archived apart out of the sandbox. `rake package:appstore` packs and packages it so:

```bash
$ export APPLE_TEAM_ID=XXXXXXXXXX
$ reflex package --pack --appstore .
$ reflex package --pack --notarize --appstore . # the generic one too
```

The app in the sandbox keeps its data in a container of its own, `~/Library/Containers/<bundle_id>/`, apart from the generic one.

Info.plist of the app has `ITSAppUsesNonExemptEncryption` of `false`, which tells Apple that it uses no encryption but the exempt one, as of HTTPS. The config has no way to change it yet, so an app with an encryption of its own is not to be packaged so.

### Releasing on GitHub

`rake release` makes the release of the tag of the version on GitHub by `gh`, with the changes of the version in `ChangeLog.md`, and attaches the zip of the app and the package for the Mac App Store, the ones made, or adds them to the release made already. It makes neither, as the jobs on CI make them apart, so archive or package the app first to release it by hand:

```bash
$ rake archive release
$ rake archive package:appstore release # the one for the Mac App Store too
```

### Uploading to App Store Connect

`rake upload:appstore` uploads the package for the Mac App Store, packaged if not yet, to App Store Connect by `altool` of Xcode, by the API key of App Store Connect in the environment variables above, which App Store Connect tells the app and the build of by the package. The app has to be made in App Store Connect beforehand, by its bundle ID, and the build is chosen for a version there to submit it for review:

```bash
$ export APPLE_TEAM_ID=XXXXXXXXXX
$ export APPLE_API_ISSUER_ID=... APPLE_API_KEY_ID=... APPLE_API_KEY_PATH=~/AuthKey_XXXXXXXXXX.p8
$ rake upload:appstore
```

A build can not be uploaded twice by the same number, so raise `version` to upload it again.

### Uploading to itch.io

With `upload.itchio.project` in the config, `rake upload:itchio` uploads the zip of the app, archived if not yet, by [butler](https://itch.io/docs/butler/), into the channel of the platform, as `macos` or `windows`, with the version of the app. butler uploads it as the user `butler login` logged in, or by the API key in `BUTLER_API_KEY`, made at https://itch.io/user/settings/api-keys, as on CI. Download butler of the platform from https://broth.itch.zone/butler, not by `brew install butler`, which is another app:

```bash
$ rake upload:itchio
```

### Packaging on GitHub Actions

The workflow `.github/workflows/package.yml` of this repository packages the app on GitHub Actions, called by the workflow of the app, and releases it when run by a tag. It packages the app for macOS and Windows, or the ones in its input `platforms`, as `platforms: macos`. With the secrets below, the app for macOS is notarized: a job on macOS submits it, one on Linux, which is cheaper, waits for it, and one on macOS again exports it. The app for Windows is not signed.

```yaml
jobs:
  release:
    uses: xord/reflex-packager/.github/workflows/package.yml@master
    secrets:
      APPLE_TEAM_ID:               ${{ secrets.APPLE_TEAM_ID }}
      APPLE_CODESIGN_P12:          ${{ secrets.APPLE_CODESIGN_P12 }} # the .p12 file in base64
      APPLE_CODESIGN_P12_PASSWORD: ${{ secrets.APPLE_CODESIGN_P12_PASSWORD }}
      APPLE_API_ISSUER_ID:         ${{ secrets.APPLE_API_ISSUER_ID }}
      APPLE_API_KEY_ID:            ${{ secrets.APPLE_API_KEY_ID }}
      APPLE_API_KEY_P8:            ${{ secrets.APPLE_API_KEY_P8 }} # the .p8 file as it is
```

For `APPLE_CODESIGN_P12`, create the certificate of Developer ID in Xcode, by Settings → Accounts → Manage Certificates, export it by Keychain Access into a `.p12` file, and put it in base64 into the secret:

```bash
$ base64 -i DeveloperID.p12 | pbcopy
```

With `APPLE_TEAM_ID` but no `APPLE_CODESIGN_P12`, the workflow fails. Without the secrets, the app is packaged with no notarization, signed as the config tells.

With the input `macos-appstore: true` and the secrets to notarize, the app for the Mac App Store is packaged too, in the job that submits the notarized one, and on a tag, attached to the release by `rake release`, then uploaded to App Store Connect by `rake upload:appstore`. It is signed by the certificate Apple manages, through the API key, which has to be of the Admin role to make the certificate and the profile, so `APPLE_CODESIGN_P12` needs no more than Developer ID. A failure of it fails the job, and the notarization with it. With the input but no `APPLE_TEAM_ID`, the workflow fails at first.

With `BUTLER_API_KEY` in the secrets too, the app released by a tag is uploaded to itch.io by `rake upload:itchio`, after it is released on GitHub, unless the input `itchio` is `false`.

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
4. Builds the `.app` bundle with `xcodebuild`, or archives and exports it signed with Developer ID, and notarized with `--notarize`
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
