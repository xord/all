// -*- objc -*-
#import "native_window.h"


#include <assert.h>
#import <Cocoa/Cocoa.h>
#include "reflex/exception.h"
#include "../view.h"
#include "../pointer.h"
#include "event.h"
#include "window.h"
#import "opengl_view.h"


static const uint MOUSE_BUTTONS =
	Reflex::Pointer::MOUSE_LEFT  |
	Reflex::Pointer::MOUSE_RIGHT |
	Reflex::Pointer::MOUSE_MIDDLE;


static NSWindowStyleMask
default_style_mask ()
{
	return Reflex::Window_make_style_mask(
		Reflex::Window_default_flags(),
		NSTitledWindowMask | NSTexturedBackgroundWindowMask);
}

static void
update_pixel_density (Reflex::Window* window)
{
	assert(window);

	Rays::Painter* painter = window->painter();
	if (!painter) return;

	float pd = Window_get_pixel_density(*window);
	if (painter->pixel_density() != pd)
	{
		painter->canvas(window->frame().dup().move_to(0, 0), pd);
		window->redraw();
	}
}

static void
move_to_main_screen_origin (NativeWindow* window)
{
	NSRect frame   = window.frame;
	NSRect screen  = NSScreen.mainScreen.visibleFrame;
	frame.origin.x = screen.origin.x;
	frame.origin.y = screen.origin.y + screen.size.height;

	[window setFrame: frame display: NO animate: NO];
}


@implementation NativeWindow

	{
		Reflex::Window *pwindow, *ptr_for_rebind;
		OpenGLView* view;
		NSTimer* timer;
		int update_count;
		Reflex::Pointer::ID pointer_id;
		Reflex::Pointer prev_pointer;
	}

	- (id) init
	{
		self = [super
			initWithContentRect: NSMakeRect(0, 0, 0, 0)
			styleMask: default_style_mask()
			backing: NSBackingStoreBuffered
			defer: NO];
		if (!self) return nil;

		pwindow         =
		ptr_for_rebind  = NULL;
		view            = nil;
		timer           = nil;
		update_count    = 0;
		pointer_id      = 0;

		[self setDelegate: self];
		[self setupContentView];
		[self startTimer];

		return self;
	}

	- (void) dealloc
	{
		assert(!pwindow);

		[self cleanupContentView];
		[super dealloc];
	}

	- (void) bind: (Reflex::Window*) window
	{
		move_to_main_screen_origin(self);

		if (!window)
			Reflex::argument_error(__FILE__, __LINE__);

		Reflex::WindowData& data = Window_get_data(window);
		if (data.native)
			Reflex::invalid_state_error(__FILE__, __LINE__);

		// ruby value references native window weakly.
		data.native = self;

		// Reflex::Window is not constructed completely,
		// so can not call ClassWrapper::retain().
		window->Xot::template RefCountable<>::retain();

		// defer calling ClassWrapper::retain() to rebind.
		ptr_for_rebind = window;
	}

	- (void) rebind
	{
		if (!pwindow && ptr_for_rebind)
		{
			pwindow = ptr_for_rebind;
			pwindow->retain();

			ptr_for_rebind->Xot::template RefCountable<>::release();
			ptr_for_rebind = NULL;
		}
	}

	- (void) unbind
	{
		[self rebind];
		if (!pwindow) return;

		Window_get_data(pwindow).native = nil;

		pwindow->release();
		pwindow = NULL;
	}

	- (Reflex::Window*) window
	{
		[self rebind];
		return pwindow;
	}

	- (void) setupContentView
	{
		NSRect rect = [self contentRectForFrameRect: [self frame]];
		rect.origin.x = rect.origin.y = 0;
		view = [[OpenGLView alloc] initWithFrame: rect];
		[self setContentView: view];
	}

	- (void) cleanupContentView
	{
		if (!view) return;

		if (view.openGLContext == NSOpenGLContext.current)
			Rays::activate_offscreen_context();

		[view release];
	}

	- (void) startTimer
	{
		[self startTimer: 60];
	}

	- (void) startTimer: (int) fps
	{
		[self stopTimer];

		if (fps <= 0) return;

		timer = [[NSTimer
			timerWithTimeInterval: 1. / (double) fps
			target: self
			selector: @selector(update:)
			userInfo: nil
			repeats: YES] retain];
		if (!timer) return;

		[[NSRunLoop mainRunLoop]
			addTimer: timer forMode: NSDefaultRunLoopMode];
		[[NSRunLoop mainRunLoop]
			addTimer: timer forMode: NSEventTrackingRunLoopMode];
	}

	- (void) stopTimer
	{
		if (!timer) return;

		[timer invalidate];
		timer = nil;
	}

	- (void) update: (NSTimer*) t
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		++update_count;

		double now = Xot::time();
		Reflex::UpdateEvent e(now, now - win->self->prev_time_update);
		win->self->prev_time_update = now;

		win->on_update(&e);
		if (!e.is_blocked())
			Reflex::View_update_tree(win->root(), e);

		if (win->self->redraw)
		{
			view.needsDisplay = YES;
			win->self->redraw = false;
		}
	}

	- (void) draw
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		update_pixel_density(win);

		if (update_count == 0)
			[self update];

		double now = Xot::time();
		double dt  = now - win->self->prev_time_draw;
		double fps = 1. / dt;

		fps = win->self->prev_fps * 0.9 + fps * 0.1;// LPF

		win->self->prev_time_draw = now;
		win->self->prev_fps       = fps;

		Reflex::DrawEvent e(dt, fps);
		Window_call_draw_event(win, &e);
	}

	- (BOOL) hasFullScreenFlag
	{
		return self.styleMask & NSWindowStyleMaskFullScreen;
	}

	- (BOOL) windowShouldClose: (id) sender
	{
		Reflex::Window* win = self.window;
		if (!win) return YES;

		win->close();
		return NO;
	}

	- (void) windowWillClose: (NSNotification*) notification
	{
		if (self.isKeyWindow)
			Window_call_deactivate_event(self.window);

		[self stopTimer];
		[self unbind];
		[self setDelegate: nil];
	}

	- (void) windowWillMove: (NSNotification*) notification
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		win->self->prev_position = win->frame().position();
	}

	- (void) windowDidMove: (NSNotification*) notification
	{
		[self frameChanged];
	}

	- (NSSize) windowWillResize: (NSWindow*) sender toSize: (NSSize) frameSize
	{
		Reflex::Window* win = self.window;
		if (!win) return frameSize;

		win->self->prev_size = win->frame().size();

		return frameSize;
	}

	- (void) windowDidResize: (NSNotification*) notification
	{
		[self frameChanged];
	}

	- (void) frameChanged
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		Rays::Bounds b           = win->frame();
		Rays::Point dpos         = b.position() - win->self->prev_position;
		Rays::Point dsize        = b.size()     - win->self->prev_size;
		win->self->prev_position = b.position();
		win->self->prev_size     = b.size();

		if (dpos != 0 || dsize != 0)
		{
			Reflex::FrameEvent e(b, dpos.x, dpos.y, 0, dsize.x, dsize.y, 0);
			if (dpos  != 0) win->on_move(&e);
			if (dsize != 0)
			{
				Rays::Bounds b = win->frame();
				b.move_to(0, 0);

				if (win->painter())
					win->painter()->canvas(b, win->painter()->pixel_density());

				if (win->root())
					View_set_frame(win->root(), b);

				win->on_resize(&e);
			}
		}
	}

	- (void) windowWillEnterFullScreen: (NSNotification*) notification
	{
		[self updateFullScreenFlag];
	}

	- (void) windowDidEnterFullScreen: (NSNotification*) notification
	{
		[self updateFullScreenFlag];
	}

	- (void) windowWillExitFullScreen: (NSNotification*) notification
	{
		[self updateFullScreenFlag];
	}

	- (void) windowDidExitFullScreen: (NSNotification*) notification
	{
		[self updateFullScreenFlag];
	}

	- (void) updateFullScreenFlag
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		bool fullscreen = self.hasFullScreenFlag;
		if (fullscreen == win->has_flag(Reflex::Window::FLAG_FULLSCREEN))
			return;

		if (fullscreen)
			win->add_flag(Reflex::Window::FLAG_FULLSCREEN);
		else
			win->remove_flag(Reflex::Window::FLAG_FULLSCREEN);
	}

	- (void) windowDidBecomeKey: (NSNotification*) notification
	{
		Window_call_activate_event(self.window);
	}

	- (void) windowDidResignKey: (NSNotification*) notification
	{
		Window_call_deactivate_event(self.window);
	}

	- (void) keyDown: (NSEvent*) event
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		Reflex::NativeKeyEvent e(event, Reflex::KeyEvent::DOWN);
		Window_call_key_event(win, &e);
	}

	- (void) keyUp: (NSEvent*) event
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		Reflex::NativeKeyEvent e(event, Reflex::KeyEvent::UP);
		Window_call_key_event(win, &e);
	}

	- (void) flagsChanged: (NSEvent*) event
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		Reflex::NativeFlagKeyEvent e(event);
		Window_call_key_event(win, &e);
	}

	- (void) mouseDown: (NSEvent*) event
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		if (Reflex::Pointer_mask_flag(prev_pointer, MOUSE_BUTTONS) == 0)
			++pointer_id;

		Reflex::NativePointerEvent e(event, view, pointer_id, Reflex::Pointer::DOWN);

		if (e[0].position().y < 0)
		{
			// ignore mouseDown event since the mouseUp event to the window title bar
			// will not come and will break clicking_count.
			return;
		}

		[self attachAndUpdatePastPointers: &e];

		Window_call_pointer_event(win, &e);
	}

	- (void) mouseUp: (NSEvent*) event
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		Reflex::NativePointerEvent e(event, view, pointer_id, Reflex::Pointer::UP);
		[self attachAndUpdatePastPointers: &e];

		if (prev_pointer && Reflex::Pointer_mask_flag(prev_pointer, MOUSE_BUTTONS) == 0)
		{
			++pointer_id;
			Pointer_set_down(&prev_pointer, NULL);
		}

		Window_call_pointer_event(win, &e);
	}

	- (void) mouseDragged: (NSEvent*) event
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		Reflex::NativePointerEvent e(event, view, pointer_id, Reflex::Pointer::MOVE);
		[self attachAndUpdatePastPointers: &e];

		Window_call_pointer_event(win, &e);
	}

	- (void) mouseMoved: (NSEvent*) event
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		Reflex::NativePointerEvent e(event, view, pointer_id, Reflex::Pointer::MOVE);
		[self attachAndUpdatePastPointers: &e];

		Window_call_pointer_event(win, &e);
	}

	- (void) attachAndUpdatePastPointers: (Reflex::PointerEvent*) e
	{
		using namespace Reflex;

		assert(e->size() == 1);

		Pointer& pointer = PointerEvent_pointer_at(e, 0);

		if (prev_pointer)
		{
			Pointer_add_flag(&pointer, Pointer_mask_flag(prev_pointer, MOUSE_BUTTONS));
			Reflex::Pointer_set_prev(&pointer, &prev_pointer);
		}

		switch (pointer.action())
		{
			case Pointer::DOWN:
				Pointer_add_flag(&pointer, pointer.types());
				break;

			case Pointer::UP:
				Pointer_remove_flag(&pointer, pointer.types());
				break;
		}

		if (prev_pointer && prev_pointer.down())
			Reflex::Pointer_set_down(&pointer, prev_pointer.down());
		else if (pointer.action() == Reflex::Pointer::DOWN)
			Reflex::Pointer_set_down(&pointer, &pointer);

		prev_pointer = pointer;
		Reflex::Pointer_set_prev(&prev_pointer, NULL);
	}

	- (void) scrollWheel: (NSEvent*) event
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		Reflex::NativeWheelEvent e(event, view);
		Window_call_wheel_event(win, &e);
	}

	+ (NSRect) frameRectForContentRect: (NSRect) contentRect
	{
		return [NSWindow
			frameRectForContentRect: contentRect
			styleMask: default_style_mask()];
	}

@end// NativeWindow
