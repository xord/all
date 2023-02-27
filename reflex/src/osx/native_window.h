// -*- objc -*-
#import <AppKit/NSWindow.h>


@interface NativeWindow : NSWindow <NSWindowDelegate>

	- (void) draw;

	+ (NSRect) frameRectForContentRect: (NSRect) contentRect;

@end// NativeWindow
