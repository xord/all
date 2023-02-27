// -*- objc -*-
#import "opengl_view.h"


#include <vector>
#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import "native_window.h"


//#define TRANSPARENT_BACKGROUND


static bool
is_valid_antialias_nsample (int n)
{
	return n == 0 || n == 2 || n == 4 || n == 6 || n == 8 || n == 16 || n == 32;
}

static NSOpenGLPixelFormat*
make_pixelformat (int antialias_nsample = 0)
{
	if (!is_valid_antialias_nsample(antialias_nsample))
		return nil;

	static const NSOpenGLPixelFormatAttribute DEFAULT[] =
	{
		//NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
		NSOpenGLPFAAccelerated, NSOpenGLPFANoRecovery,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAColorSize, 32,
		NSOpenGLPFADepthSize, 32,
	};
	static const NSOpenGLPixelFormatAttribute ANTIALIAS[] =
	{
		NSOpenGLPFAMultisample,
		NSOpenGLPFASampleBuffers, 1,
		NSOpenGLPFASamples, (NSOpenGLPixelFormatAttribute) antialias_nsample,
	};
	static const size_t DEFAULT_SIZE   = sizeof(DEFAULT)   / sizeof(DEFAULT[0]);
	static const size_t ANTIALIAS_SIZE = sizeof(ANTIALIAS) / sizeof(ANTIALIAS[0]);

	std::vector<NSOpenGLPixelFormatAttribute> attr(
		DEFAULT, DEFAULT + DEFAULT_SIZE);
	if (antialias_nsample > 0)
		attr.insert(attr.end(), ANTIALIAS, ANTIALIAS + ANTIALIAS_SIZE);
	attr.push_back(0);

	return [[[NSOpenGLPixelFormat alloc] initWithAttributes: &attr[0]] autorelease];
}


@implementation OpenGLView

	- (id) initWithFrame: (NSRect) frame
	{
		return [self initWithFrame: frame antiAlias: 0];
	}

	- (id) initWithFrame: (NSRect) frame antiAlias: (int) nsample
	{
		self = [super initWithFrame: frame pixelFormat: make_pixelformat(nsample)];
		if (!self) return nil;

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
		[[self openGLContext] makeCurrentContext];
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
