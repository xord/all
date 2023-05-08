# rays ChangeLog


## [v0.1.35] - 2023-05-08

- Update dependencies


## [v0.1.34] - 2023-04-30

- Test Image#size


## [v0.1.33] - 2023-04-22

- Update external libraries
- save_image(image, path) -> Image::save(path)


## [v0.1.32] - 2023-03-01

- fix bugs


## [v0.1.31] - 2023-02-27

- add ChangeLog.md file
- add test.yml, tag.yaml, and release.yml
- requires ruby 2.7.0 or later


## [v0.1.30] - 2023-02-09

- default precision: mediump -> highp
- do not use buffer object to draw on iOS
- fix conflicting rays's Init_exception() and others Init_exception()
- disable non-power-of-two texture by default
- restore premultiplied rgb values of the font texture on iOS
- fix buffer leak
- fix compile errors on building for iOS
- refactoring
