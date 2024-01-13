// -*- objc -*-
#import <AppKit/NSWindow.h>


@interface NativeWindow : NSWindow <NSWindowDelegate>

	- (void) draw;

	- (BOOL) hasFullScreenFlag;

	+ (NSRect) frameRectForContentRect: (NSRect) contentRect;

@end// NativeWindow
