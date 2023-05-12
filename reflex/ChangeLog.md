# reflex ChangeLog


## [v0.1.38] - 2023-05-13

- View: Reimplemented from_parent(), to_parent(), from_window(), to_window(), from_screen(), and to_screen() to account for rotation, zoom, and scrolling during coordinate transformation


## [v0.1.37] - 2023-05-11

- Update dependencies


## [v0.1.36] - 2023-05-08

- Add inspect()
- Add View#pivot accessor
- Awake view body on every pointer event
- Disable blocking event escalation
- Check is view valid before calling event handlers
- Fix pointer position for rotated view


## [v0.1.35] - 2023-04-30

- Add View#on_zoom(e)


## [v0.1.34] - 2023-04-25

- Update beeps to v0.1.34


## [v0.1.33] - 2023-04-22

- Add will_contact?()
- Delete category_bits and collision_mask
- Update Box2D to 2.4.1


## [v0.1.32] - 2023-03-01

- fix bugs


## [v0.1.31] - 2023-02-27

- add ChangeLog.md file
- add test.yml, tag.yaml, and release.yml
- requires ruby 2.7.0 or later


## [v0.1.30] - 2023-02-09

- fix conflicting reflex's Init_exception() and others Init_exception()
- refactoring
