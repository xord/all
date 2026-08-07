// -*- objc -*-
#import <AppKit/NSWindow.h>


@interface NativeWindow : NSWindow <NSWindowDelegate>

	- (void) draw;

	- (BOOL) hasFullScreenFlag;

	- (BOOL) isTextInputEnabled;

	- (void) textEdit: (NSString*) text selection: (NSRange) selection;

	- (void) textCommit: (NSString*) text synthesizeKeyEvent: (BOOL) synthesize;

	- (NSRect) textInputBounds;

	+ (NSRect) frameRectForContentRect: (NSRect) contentRect;

@end// NativeWindow
