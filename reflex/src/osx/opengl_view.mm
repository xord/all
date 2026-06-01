// -*- objc -*-
#import "opengl_view.h"


#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#include <rays/rays.h>
#import "native_window.h"


//#define TRANSPARENT_BACKGROUND


@implementation OpenGLView

	- (id) initWithFrame: (NSRect) frame
	{
		return [self initWithFrame: frame antiAlias: 0];
	}

	- (id) initWithFrame: (NSRect) frame antiAlias: (int) nsample
	{
		NSOpenGLContext* context = (NSOpenGLContext*) Rays::get_offscreen_context();

		self = [super initWithFrame: frame pixelFormat: context.pixelFormat];
		if (!self) return nil;

		[self setOpenGLContext: context];
		[self setWantsBestResolutionOpenGLSurface: YES];
		[self activateContext];

		GLint swapInterval = 1;
		[[self openGLContext]
			setValues: &swapInterval
			forParameter: NSOpenGLCPSwapInterval];

#ifdef TRANSPARENT_BACKGROUND
		GLint opacity = 0;
		[[self openGLContext]
			setValues: &opacity
			forParameter: NSOpenGLCPSurfaceOpacity];
#endif

		return self;
	}

	- (void) activateContext
	{
		NSOpenGLContext* context = self.openGLContext;
		if (context.view != self) [context setView: self];
		[context makeCurrentContext];
	}

	- (BOOL) acceptsFirstResponder
	{
		return YES;
	}

	- (BOOL) acceptsFirstMouse: (NSEvent*) event
	{
		return YES;
	}

#ifdef TRANSPARENT_BACKGROUND
	- (BOOL) isOpaque
	{
		return YES;
	}
#endif

	- (void) drawRect: (NSRect) rect
	{
		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[self activateContext];
		[win draw];
		[[NSOpenGLContext currentContext] flushBuffer];
	}

	- (void) viewDidMoveToWindow
	{
		[[self window] setAcceptsMouseMovedEvents: YES];
		[[self window] makeFirstResponder: self];

#ifdef TRANSPARENT_BACKGROUND
		[[self window] setBackgroundColor: [NSColor clearColor]];
		[[self window] setOpaque: NO];
#endif
	}

	- (void) insertText: (id) str
	{
		//NSLog(@"interText: %@", str);
	}

	- (void) keyDown: (NSEvent*) event
	{
		//[self interpretKeyEvents: [NSArray arrayWithObject: event]];

		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[win keyDown: event];
	}

	- (void) keyUp: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[win keyUp: event];
	}

	- (void) flagsChanged: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[win flagsChanged: event];
	}

	- (void) mouseDown: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[win mouseDown: event];
	}

	- (void) mouseUp: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[win mouseUp: event];
	}

	- (void) mouseDragged: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[win mouseDragged: event];
	}

	- (void) rightMouseDown: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[win mouseDown: event];
	}

	- (void) rightMouseUp: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[win mouseUp: event];
	}

	- (void) rightMouseDragged: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[win mouseDragged: event];
	}

	- (void) otherMouseDown: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[win mouseDown: event];
	}

	- (void) otherMouseUp: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[win mouseUp: event];
	}

	- (void) otherMouseDragged: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[win mouseDragged: event];
	}

	- (void) mouseMoved: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[win mouseMoved: event];
	}

@end// OpenGLView
