# rays ChangeLog


## [v0.1.38] - 2023-05-27

- required_ruby_version >= 3.0.0
- Add spec.license


## [v0.1.37] - 2023-05-18

- Update dependencies


## [v0.1.36] - 2023-05-11

- Fix a few minor problems


## [v0.1.35] - 2023-05-08

- Update dependencies


## [v0.1.34] - 2023-04-30

- Test Image#size


## [v0.1.33] - 2023-04-22

- Update external libraries
- Save_image(image, path) -> Image::save(path)


## [v0.1.32] - 2023-03-01

- Fix bugs


## [v0.1.31] - 2023-02-27

- Add ChangeLog.md file
- Add test.yml, tag.yaml, and release.yml
- Requires ruby 2.7.0 or later


## [v0.1.30] - 2023-02-09

- Default precision: mediump -> highp
- Do not use buffer object to draw on iOS
- Fix conflicting rays's Init_exception() and others Init_exception()
- Disable non-power-of-two texture by default
- Restore premultiplied rgb values of the font texture on iOS
- Fix buffer leak
- Fix compile errors on building for iOS
- Refactoring
