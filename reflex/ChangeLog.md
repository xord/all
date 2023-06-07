# reflex ChangeLog


## [v0.1.43] - 2023-06-07

- Add on_activate() and on_deactivate() to Window class


## [v0.1.42] - 2023-06-02

- Implement the Screen class for iOS
- Implement Window_get_screen() for iOS
- Implement window flags for iOS
- Update reflexView's size on viewDidLayoutSubviews


## [v0.1.41] - 2023-05-29

- Add Reflex::Screen class
- Add Window#closable and Window#minimizable accessors
- Fix that non-closable, non-minimizable, or non-resizable buttons raise error on clicking them


## [v0.1.40] - 2023-05-27

- required_ruby_version >= 3.0.0
- Add FLAG_FIX_ANGLE
- Add spec.license
- Fix crash on calling ContactEvent#inspect


## [v0.1.39] - 2023-05-18

- Event#block has a bool parameter, which defaults to true
- Add z and depth value to FrameEvent class
- Sort child views by z position
- Add Pointer#view_index


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

- Fix bugs


## [v0.1.31] - 2023-02-27

- Add ChangeLog.md file
- Add test.yml, tag.yaml, and release.yml
- Requires ruby 2.7.0 or later


## [v0.1.30] - 2023-02-09

- Fix conflicting reflex's Init_exception() and others Init_exception()
- Refactoring
