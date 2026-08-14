// -*- objc -*-
#import <AppKit/NSWindow.h>


@interface NativeWindow : NSWindow <NSWindowDelegate>

	- (void) setTitlebarBackgroundVisible: (BOOL) visible;

	- (void) setTitlebarButtonsVisible: (BOOL) visible;

	- (void) setBackgroundTransparent: (BOOL) transparent;

	- (BOOL) hasFullScreenFlag;

	- (void) draw;

	- (BOOL) isTextInputEnabled;

	- (void) textPreedit: (NSString*) text selection: (NSRange) selection;

	- (void) textCommit: (NSString*) text synthesizeKeyEvent: (BOOL) synthesize;

	- (NSRect) textInputBounds;

	+ (NSRect) frameRectForContentRect: (NSRect) contentRect;

@end// NativeWindow
