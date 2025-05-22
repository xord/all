# xot ChangeLog


## [v0.3.8] - 2025-05-22

- Add Xot::range_error()


## [v0.3.7] - 2025-05-11

- Delete Xot::clip(), and use std::clamp()


## [v0.3.6] - 2025-04-08

- Move cfrelease() and CFStringPtr from rays to xot


## [v0.3.5] - 2025-03-24

- Add PULL_REQUEST_TEMPLATE.md
- Add CONTRIBUTING.md


## [v0.3.4] - 2025-03-07

- Hookable passes keyword args
- Xot::Hookable#on defines methods that contain the 'on_' prefix


## [v0.3.3] - 2025-01-23

- Fix '=bar' in CFLAGS when '-Wfoo=bar' is included in CFLAGS, which leaves only '=bar' in CFLAGS and causes a compile error


## [v0.3.2] - 2025-01-14

- Update workflow files


## [v0.3.1] - 2025-01-13

- Update LICENSE


## [v0.3] - 2024-07-06

- Support Windows


## [v0.2.1] - 2024-07-05

- Add xot/util.rb
- Add system_error_text()
- Add get_refc_count() for debugging
- Add 'packages' task
- Update workflows for test
- Update to actions/checkout@v4
- Fix 'github_actions?'


## [v0.2] - 2024-03-14

- v0.2


## [v0.1.42] - 2024-02-07

- Add Xot::split()
- Fix compile error


## [v0.1.41] - 2023-12-09

- Add ci?()
- Trigger github actions on all pull_request
- Fix breaking depend.mf


## [v0.1.40] - 2023-11-09

- Use Gemfile to install gems for development instead of add_development_dependency in gemspec


## [v0.1.39] - 2023-06-11

- Add mask_flag()


## [v0.1.38] - 2023-05-29

- Refactoring


## [v0.1.37] - 2023-05-27

- required_ruby_version >= 3.0.0
- Add spec.license


## [v0.1.36] - 2023-05-18

- Fix crash on copying to null pimpl


## [v0.1.35] - 2023-05-08

- Add xot/inspectable.rb


## [v0.1.34] - 2023-04-30

- Fix bugs


## [v0.1.33] - 2023-04-22

- Use '-isystem' option for vendor headers
- Disable warnings on compiling vendor sources
- OSX: add '-Wl,-undefined,dynamic_lookup' to ldflags
- Add VENDOR_NOCOMPILE option
- Rakefile: add 'quiet' option


## [v0.1.32] - 2023-03-01

- Fix bugs


## [v0.1.31] - 2023-02-26

- Add ChangeLog.md file
- Add test.yml, tag.yaml, and release.yml
- Requires ruby 2.7.0 or later


## [v0.1.30] - 2023-02-09

- Refactoring
