// -*- objc -*-
#import <AppKit/NSOpenGLView.h>
#import <AppKit/NSTextInputClient.h>


@interface OpenGLView : NSOpenGLView <NSTextInputClient>

	- (id) initWithFrame: (NSRect) frame;

	- (id) initWithFrame: (NSRect) frame antiAlias: (int) nsample;

@end// OpenGLView
