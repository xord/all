# reflex-packager ChangeLog


## [v0.3.0] - 2026-11-04

- [BREAKING] Build a macOS app without CocoaPods, from the sources in the installed gems
- [BREAKING] Put the files of a build in .build/, and the packages in dist/ by their variant, as dist/generic/ and dist/adhoc/
- [BREAKING] Name the .app by the name of the app with spaces
- [BREAKING] Refuse a version that YAML reads as a number, as 1.10 without quotes
- [BREAKING] Refuse a version of more than three numbers on macOS
- Package an app for Windows by --platform windows
- Package for the platform the packager runs on, and a universal macOS app, by default
- Compile the scripts of an app into a data file by --pack
- Sign and notarize a macOS app, by --notarize and --notarize-wait
- Package an app for the Mac App Store by --appstore, and upload it to App Store Connect by rake upload:appstore
- Upload an app to itch.io by rake upload:itchio
- Add the workflow to test, package and release an app, for the apps to call
- Add copyright and localizations to the config
- Add excludes: to the config, to leave files out of the app
- Read the version of an app from its VERSION file
- Set CFBundleVersion from the version, not 1
- Name the zip by the platform and the architecture, as macos-universal or windows-x64
- Show the error an app dies of with Reflex.alert, with the paths in the package
- Quiet the build of a macOS app unless verbose
- Embed CRuby 4.0.701 with Ruby 4.0.7
- Add a hello example to try packaging with

- Fix an app in a folder of a non-ASCII name exiting with no output on macOS
- Fix a directory of the app being copied again into its copy


## [v0.2.0] - 2026-08-04

- [BREAKING] Replace Profile#template with a templates Hash
- Add boot script support to Profile
- Add command field to Profile for the CLI display name


## [v0.1.5] - 2026-06-23

- Update dependencies


## [v0.1.4] - 2026-06-23

- Update dependencies


## [v0.1.3] - 2026-06-23

- Update dependencies


## [v0.1.2] - 2026-06-23

- Add yard to Gemfile for doc generation in CI


## [v0.1.1] - 2026-06-23

- First gem release


## [v0.1.0] - 2026-06-23

- Initial release
