// -*- objc -*-
#import "opengl_view.h"


#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#include <rays/rays.h>
#import "native_window.h"



@implementation OpenGLView

	{
		bool setup_context_done;
		GLint surface_opacity;
		NSTrackingArea* tracking_area;

		// the text being composed by the input method
		NSString* marked_text;

		// the clause being converted, relative to marked_text
		NSRange marked_selection;

		// whether marked text existed when the current keyDown: started
		BOOL was_marked;

		// whether the input method handled the key in the current keyDown:
		BOOL consumed_by_ime;
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
		surface_opacity    = 1;
		tracking_area      = nil;
		marked_text        = nil;
		marked_selection   = NSMakeRange(NSNotFound, 0);
		was_marked         = NO;
		consumed_by_ime    = NO;

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
	}

	- (void) activateContext
	{
		[self setupContext];

		NSOpenGLContext* context = self.openGLContext;
		BOOL moved               = context.view != self;
		if (moved) [context setView: self];
		[context makeCurrentContext];

		GLint opacity = !self.window || self.window.isOpaque ? 1 : 0;
		if (moved || opacity != surface_opacity)
		{
			surface_opacity = opacity;
			[context setValues: &opacity forParameter: NSOpenGLCPSurfaceOpacity];
		}
	}

	- (BOOL) acceptsFirstResponder
	{
		return YES;
	}

	- (BOOL) acceptsFirstMouse: (NSEvent*) event
	{
		return YES;
	}

	- (BOOL) isOpaque
	{
		return self.window ? self.window.isOpaque : YES;
	}

	- (void) drawRect: (NSRect) rect
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[self activateContext];
		[win draw];
		[[NSOpenGLContext currentContext] flushBuffer];
	}

	- (void) viewDidMoveToWindow
	{
		[self.window setAcceptsMouseMovedEvents: YES];
		[self.window makeFirstResponder: self];
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
		[self clearMarkedText];
		[super dealloc];
	}

	- (void) keyDown: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		was_marked      = self.hasMarkedText;
		consumed_by_ime = NO;

		if (win.isTextInputEnabled)
			[self interpretKeyEvents: [NSArray arrayWithObject: event]];

		if (!consumed_by_ime)
			[win keyDown: event];
	}

	- (void) keyUp: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[win keyUp: event];
	}

	- (void) flagsChanged: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[win flagsChanged: event];
	}

	- (void) mouseDown: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[win mouseDown: event];
	}

	- (void) mouseUp: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[win mouseUp: event];
	}

	- (void) mouseDragged: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[win mouseDragged: event];
	}

	- (void) rightMouseDown: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[win mouseDown: event];
	}

	- (void) rightMouseUp: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[win mouseUp: event];
	}

	- (void) rightMouseDragged: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[win mouseDragged: event];
	}

	- (void) otherMouseDown: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[win mouseDown: event];
	}

	- (void) otherMouseUp: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[win mouseUp: event];
	}

	- (void) otherMouseDragged: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[win mouseDragged: event];
	}

	- (void) mouseMoved: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[win mouseMoved: event];
	}

	- (void) mouseEntered: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[win mouseEntered: event];
	}

	- (void) mouseExited: (NSEvent*) event
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[win mouseExited: event];
	}

	static NSString*
	to_string (id str)
	{
		return [str isKindOfClass: NSAttributedString.class]
			?	[(NSAttributedString*) str string]
			:	(NSString*) str;
	}

	- (void) insertText: (id) string replacementRange: (NSRange) range
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		// text committed from a composition session, or inserted without a key
		// event (candidate window, emoji palette, dictation), has no key to
		// report, so a key event is synthesized for it.
		// otherwise, let keyDown: deliver the original key event.
		BOOL synthesize = was_marked || NSApp.currentEvent.type != NSKeyDown;
		consumed_by_ime = synthesize;

		[self clearMarkedText];
		[win textCommit: to_string(string) synthesizeKeyEvent: synthesize];
	}

	- (void) setMarkedText: (id) string
		selectedRange: (NSRange) selection
		replacementRange: (NSRange) range
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		NSString* text  = to_string(string);
		consumed_by_ime = YES;

		[self clearMarkedText];
		if (text.length > 0)
		{
			marked_text      = [text retain];
			marked_selection = selection;
		}

		[win textPreedit: text selection: selection];
	}

	- (void) unmarkText
	{
		if (!marked_text) return;

		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return;

		[self clearMarkedText];
		[win textPreedit: @"" selection: NSMakeRange(NSNotFound, 0)];
	}

	- (BOOL) hasMarkedText
	{
		return marked_text != nil;
	}

	- (NSRange) markedRange
	{
		return marked_text
			?	NSMakeRange(0, marked_text.length)
			:	NSMakeRange(NSNotFound, 0);
	}

	- (NSRange) selectedRange
	{
		return marked_selection;
	}

	- (void) clearMarkedText
	{
		if (marked_text)
		{
			[marked_text release];
			marked_text = nil;
		}
		marked_selection = NSMakeRange(NSNotFound, 0);
	}

	- (NSRect) firstRectForCharacterRange: (NSRange) range
		actualRange: (NSRangePointer) actual
	{
		NativeWindow* win = (NativeWindow*) self.window;
		if (!win) return NSZeroRect;

		NSRect rect = win.textInputBounds;
		return [win convertRectToScreen: [self convertRect: rect toView: nil]];
	}

	- (NSAttributedString*) attributedSubstringForProposedRange: (NSRange) range
		actualRange: (NSRangePointer) actual
	{
		return nil;
	}

	- (NSUInteger) characterIndexForPoint: (NSPoint) point
	{
		return NSNotFound;
	}

	- (NSArray*) validAttributesForMarkedText
	{
		return [NSArray array];
	}

	- (void) doCommandBySelector: (SEL) selector
	{
		// NSResponder's default beeps for unhandled selectors, and keyDown:
		// delivers the event as a key event anyway.
	}

@end// OpenGLView
