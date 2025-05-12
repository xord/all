# reflex ChangeLog


## [v0.3.8.1] - 2025-05-13

- Fix a crash that occasionally occurred at startup when a MIDI device was connected


## [v0.3.8] - 2025-05-12

- Initialize gamepad and MIDI devices after the application startup process


## [v0.3.7] - 2025-05-11

- Add MIDI class
- Add NoteEvent class and on_note and on_note_on/off event handlers
- Add reflex/test/test_note_event.rb
- KeyEvent can take 'time' parameter


## [v0.3.6] - 2025-04-08

- Add Gamepad class
- Add Device and DeviceEvent classes
- Add Application#on_device_connect/disconnect
- Add Application_call_start() and Application_call_quit()


## [v0.3.5] - 2025-03-24

- Add PULL_REQUEST_TEMPLATE.md
- Add CONTRIBUTING.md
- Handle gamepad events on macOS, iOS, and Win32
- Call activate/deactivate event for window on Win32
- Define constants for gamepad keys
- Delay removing child to avoid breaking child list looped on View_update_tree()

- Fix a crash caused by add/remove_child()


## [v0.3.4] - 2025-03-07

- Captured key and pointer events can be blocked before being sent to the window and views
- Apply pixel<->meter scale to linear velocity and linear damping
- Call awake() after moving the view

- Fix an issue where capturing keys do not work


## [v0.3.3] - 2025-01-23

- Remove dependence on the beeps library
- Add Application#windows

- Fix frame rate limitation on Windows


## [v0.3.2] - 2025-01-14

- Update workflow files
- Set minumum version for runtime dependency


## [v0.3.1] - 2025-01-13

- Add View#create_world(pixels_per_meter)
- Rename View#update_physics to View#update_world
- Delete Pointer#view_index
- Update LICENSE

- Fix crash in unregister_captures() called immediately after deleting a view
- Fix that incorrect determination whether the pointer is in a view or not
- Fix a bug that caused some pointer events to be ignored in zoomed views


## [v0.3] - 2024-07-06

- Support Windows


## [v0.2.1] - 2024-07-05

- Use native values for key codes
- KeyEvent#chars returns nil
- KeyEvent#inspect prints 'key' value
- MOD_ALT -> MOD_OPTION
- Do not redefine fin!() methods, they are no longer needed
- Refactoring: Pointer#down
- Update workflows for test
- Update to actions/checkout@v4
- Fix duplicated prev pointer


## [v0.2] - 2024-03-14

- Change the super class for exception class from RuntimeError to StandardError


## [v0.1.57] - 2024-02-07

- Add Window#fullscreen accessor
- Window now appears on active screen when displayed

- Fix Window#set_frame updating to a position that was lower than the correct position by the height of the window title bar
- Fix a bug that the window position origin (0, 0) was at the bottom-left corner of the screen; now it is at the top-left corner of the screen


## [v0.1.56] - 2024-01-08

- Delete Polygon::Line because it was merged into Polyline


## [v0.1.55] - 2023-12-09

- Trigger github actions on all pull_request


## [v0.1.54] - 2023-11-09

- Use Gemfile to install gems for development instead of add_development_dependency in gemspec


## [v0.1.53] - 2023-10-29

- Update dependencies


## [v0.1.52] - 2023-10-25

- Add '#include <assert.h>' to Fix compile errors


## [v0.1.51] - 2023-07-30

- Fix typo


## [v0.1.50] - 2023-07-30

- Add Window::FLAG_PORTRAIT and Window::FLAG_LANDSCAPE
- Add Reflex.vibrate()


## [v0.1.49] - 2023-07-11

- Fix assertion fail if the view size is 0


## [v0.1.48] - 2023-07-10

- Fix a problem that a rectangle shape would be split into 2 triangles for physics


## [v0.1.47] - 2023-06-27

- NONE -> TYPE_NONE


## [v0.1.46] - 2023-06-22

- Use UIScreen's 'nativeScale' instead of 'scale'
- Fix invalid dz value for FrameEvent


## [v0.1.45] - 2023-06-11

- Add Pointer#down() which saves the first 'pointer_down' pointer
- PointerEvent includes Enumerable
- Rename Pointer#type to Pointer#types


## [v0.1.44] - 2023-06-08

- Fix compile error


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
