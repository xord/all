// -*- objc -*-
#import "opengl_view.h"


#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#include <rays/rays.h>
#import "native_window.h"


//#define TRANSPARENT_BACKGROUND


@implementation OpenGLView

	{
		bool setup_context_done;
		NSTrackingArea* tracking_area;
	}

	- (id) initWithFrame: (NSRect) frame
	{
		return [self initWithFrame: frame antiAlias: 0];
	}

	- (id) initWithFrame: (NSRect) frame antiAlias: (int) nsample
	{
		NSOpenGLContext* context = (NSOpenGLContext*) Rays::get_offscreen_context();

		self = [super initWithFrame: frame pixelFormat: context.pixelFormat];
		if (!self) return nil;

		setup_context_done = false;
		tracking_area      = nil;

		return self;
	}

	- (void) setupContext
	{
		if (setup_context_done) return;
		setup_context_done = true;

		[self setWantsBestResolutionOpenGLSurface: YES];

		NSOpenGLContext* context = (NSOpenGLContext*) Rays::get_offscreen_context();
		[self setOpenGLContext: context];

		GLint swapInterval = 1;
		[context setValues: &swapInterval forParameter: NSOpenGLCPSwapInterval];

#ifdef TRANSPARENT_BACKGROUND
		GLint opacity = 0;
		[context setValues: &opacity forParameter: NSOpenGLCPSurfaceOpacity];
#endif
	}

	- (void) activateContext
	{
		[self setupContext];

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

	- (void) updateTrackingAreas
	{
		[super updateTrackingAreas];

		if (tracking_area)
		{
			[self removeTrackingArea: tracking_area];
			[tracking_area release];
		}

		// to track pointer enter/leave event of the window bounds
		tracking_area = [[NSTrackingArea alloc]
			initWithRect: NSZeroRect
			options:
				NSTrackingMouseEnteredAndExited |
				NSTrackingActiveAlways |
				NSTrackingInVisibleRect
			owner: self
			userInfo: nil];
		[self addTrackingArea: tracking_area];
	}

	- (void) dealloc
	{
		if (tracking_area)
		{
			[self removeTrackingArea: tracking_area];
			[tracking_area release];
			tracking_area = nil;
		}
		[super dealloc];
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

	- (void) mouseEntered: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[win mouseEntered: event];
	}

	- (void) mouseExited: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) [self window];
		if (!win) return;

		[win mouseExited: event];
	}

@end// OpenGLView
