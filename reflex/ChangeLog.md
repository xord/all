# reflex ChangeLog


## [v0.7.0] - 2026-11-04

- [BREAKING] Rename View#cache to View#draw_cache
- [BREAKING] Rename Window#hidden to Window#hidden?
- [BREAKING] Make Menu#shortcut_key a key symbol, not a string
- [BREAKING] Return only the shortcut modifiers from #modifiers by default
- [BREAKING] Report wheel deltas in pixels, in the same direction, on every platform
- [BREAKING] Make the window frame the client rect on Windows, as it is the content rect on macOS
- [BREAKING] Open gamepads and MIDI only when Gamepad.enable / MIDI.enable is called
- [BREAKING] Return from Reflex.start on quit on macOS too, and raise the exception of a callback from it
- [BREAKING] Raise the deployment targets to macOS 11.0 and iOS 14.0
- Add TextEvent, on_text_preedit and on_text_commit to take text from an input method
- Add HasTextPreedit for views taking text input
- Add FileDialog to open the file dialog of the platform
- Add ColorPicker to open the color picker of the platform
- Add Reflex.alert to show a message and wait for it to be closed
- Add Application#background for an app with no dock icon, with its menu in the menu bar or the tray
- Add Window#transparent= and #shadow=
- Add the :buttons and :background flags to Window#titlebar to hide the parts of the titlebar
- Add Window#always_on_top and #always_on_bottom
- Add Window::FLAG_POINTER_THROUGH and Window#pointer_through_alpha to let pointers go through a window
- Add Window#unlisted= to keep a window out of Mission Control, the taskbar and alt-tab
- Add Screen.all, Screen#name and #pixel_density
- Add Reflex::KEYS and Reflex.get_key_symbol!
- Add ControlChangeEvent#inspect
- Handle non-ASCII text on Windows
- Support High DPI on Windows
- Deliver MIDI events to every window, also while the app is in the background
- End every pointer press with an up or a cancel, also when a menu pops up or the pointer leaves the window
- Decide the enter and leave of a window from where the pointer is
- Stop hover moves at the edge of a window on macOS, as on the other platforms
- Let handlers add and remove views while events are dispatched
- Name an application by the name the system has for it by default
- Give windows the icon of the executable on Windows
- Keep the caption on screen when placing a window on Windows
- Leave the time a popup menu is open on Windows out of the next dt
- Make Window#close do nothing on a window already closed
- Let Window#titlebar and #orientations be called as universal accessors

- Fix menu shortcuts never firing on macOS and Windows
- Fix closable, minimizable and resizable doing nothing on Windows
- Fix the window flags taking effect one change late on macOS
- Fix a block given to Window.new or Reflex.start being lost when on(:show) or on(:start) is hooked
- Fix views added to a window already shown never being drawn
- Fix a drag not working on Windows right after a popup menu
- Fix MIDI.all returning true for each device
- Fix the MIDI input thread corrupting the heap
- Fix a crash when removing two or more gamepads
- Fix RtMidi running the event loop of the app on macOS
- Fix the extension failing to load on Windows without the DirectX redistributable
- Fix linking the extension statically on macOS
- Fix the build for iOS


## [v0.6.0] - 2026-08-04

- [BREAKING] Read modifiers as symbols from every event that carries them
- [BREAKING] Rename KEY_APPS to KEY_CONTEXT_MENU and fix its macOS keycode
- [BREAKING] Sync view frames on View#update_world, drop its duration argument
- Add Menu class and Application#menu
- Add Constraint classes backed by Box2D joints
- Add Clipboard class
- Add on_pointer_enter/leave event handlers to View and Window
- Add on_activate/deactivate event handlers to View
- Add index argument to View#add_child and #add_shape
- Add locks: option to modifiers for excluding caps/num/scroll lock
- Add midi and gamepad to the umbrella header
- Add menu and constraint samples
- Give View#each_* an enumerator form and array-returning plural accessors
- Make View#each_* safe against removals during iteration
- Fill in the Windows virtual-key codes for punctuation and numpad operators
- Report fn+return as the keypad enter on macOS

- Fix crash when an empty array is passed where a Pin or Selector is expected
- Fix get_modifiers reporting only the first modifier held
- Fix reversed selector match in find_shapes and find_styles
- Fix view clipping to track ancestor zoom and position in screen space


## [v0.5.3] - 2026-06-23

- Run vendor and erb for reflex itself in pod.rake setup


## [v0.5.2] - 2026-06-23

- Add include, ext, vendor to podspec preserve_paths


## [v0.5.1] - 2026-06-23

- Replace monorepo-based pod.rake with per-repo clone approach


## [v0.5.0] - 2026-06-23

- Upgrade Box2D from 2.4.1 to 3.1.1
- Add Reflex.podspec and pod.rake for CocoaPods distribution
- Define ==/eql?/hash on RefCountable wrapper classes
- Build the menu in applicationWillFinishLaunching

- Fix Timer owner use-after-free with WeakRef
- Fix rect fixture bottom edge and wall shape setup


## [v0.4.2] - 2026-06-12

- Share single offscreen GL context across windows
- Apply GC-root rebind pattern to window lifecycle on Win32 and SDL
- Lazy-initialize OpenGL context until first drawRect:
- Fire on_close by the close button on SDL
- Do not destroy the view tree in Window#close to survive closing on event handlers
- Add multi_window sample to demonstrate cross-window texture sharing

- Fix iterator invalidation in View::clear_children


## [v0.4.1] - 2026-05-20

- Track actual key repeat count on macOS
- Add key repeat on iOS


## [v0.4.0] - 2026-05-17

- [BREAKING] Normalize wheel Y delta to top-left origin convention

- Add keyboard event handling on iOS
- Add mouse event handling on iOS
- Rewrite README.md
- CI: Migrate release-gem.yml from actions/create-release to gh release create
- Refresh hello sample Xcode projects

- Skip duplicate KEY_CODE aliases on WASM build


## [v0.3.15] - 2026-05-10

- Support WebAssembly
- Dispatch SDL touch events as multi-pointer PointerEvents
- Add SDL scancode mapping and input event handling
- Enable HiDPI support on SDL backend
- Handle SDL_QUIT via app->quit() instead of breaking loop
- Remove deprecated has_rdoc= from gemspecs

- Fix quit re-entrancy in Application_call_quit


## [v0.3.14] - 2026-04-17

- Fix HID gamepad stick direction release not firing on direction switch


## [v0.3.13] - 2026-04-10

- Revert "Work around macOS 15 HID gamepad Y-axis inversion"


## [v0.3.12] - 2026-04-10

- Work around macOS 15 HID gamepad Y-axis inversion


## [v0.3.11] - 2026-04-09

- Add minimal support for SDL2
- Add 'apt' for install_packages()
- Check is_blocked() before dispatching wheel event
- Change C-Extension name from 'native.so' to 'reflex_ext.so'
- Captured key and pointer events cannot prevent the event from being sent to the window
- Update dependencies

- Fix coordinate transformation for wheel event
- Fix touch continuity by using UITouch address as system ID (UP event coords may shift on iOS)
- Fix USB gamepad not detected on macOS 11+
- Fix inverted Y-axis stick button events in HID gamepad


## [v0.3.10] - 2025-07-06

- Add deepwiki badge
- Define __WINDOWS_MM__ macro on Windows


## [v0.3.9] - 2025-05-22

- Add MIDIEvent class and on_midi() event handler
- Add ControlChangeEvent and on_control_change() event handler
- Replace capture type from CAPTURE_NOTE to CAPTURE_MIDI


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
