// -*- objc -*-
#import <AppKit/NSOpenGLView.h>


@interface OpenGLView : NSOpenGLView

	- (id) initWithFrame: (NSRect) frame;

	- (id) initWithFrame: (NSRect) frame antiAlias: (int) nsample;

@end// OpenGLView
