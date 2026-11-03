# reflex-terminal ChangeLog


## [v0.2.0] - 2026-11-04

- [BREAKING] each_span yields (x, y, width, text, fg, bg, ul, flags), with the underline color beside the other colors
- [BREAKING] Leave the focus to the application, instead of TerminalView taking it when attached
- [BREAKING] Update libghostty-vt to the latest main, which requires Zig 0.17.0
- Draw bold and italic faces, underlines, strikethrough, overline, the underline color of SGR 58, and concealed and blinking text
- Draw faint text faintly
- Let the terminal take Japanese input
- Let the terminal background be seen through, by background_alpha:
- Let the terminal example change its font size

- Fix the build on Windows
- Fix the wheel never scrolling the terminal
- Fix the text of a released key being written a second time
- Fix the gaps between glyphs being a pixel wider here and there
- Fix the antialiased edges of glyphs being drawn too thin
- Fix the cursor not moving on screen until the next blink
- Fix the mouse position drifting toward the right edge
- Fix the function keys of macOS typing a character under the kitty keyboard protocol
- Fix the child process living on after the pty is closed
- Fix a canceled press leaving a selection or a button held


## [v0.1.0] - 2026-08-04

- Initial release
