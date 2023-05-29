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


static NSWindowStyleMask
default_style_mask ()
{
	return Window_make_style_mask(
		Reflex::Window::Data::FLAG_DEFAULT,
		NSTitledWindowMask | NSTexturedBackgroundWindowMask);
}

static int
count_mouse_buttons (const Reflex::PointerEvent& e)
{
	uint nbuttons = 0;
	PointerEvent_each_pointer(&e, [&](const auto& pointer) {
		uint t = pointer.type();
		nbuttons +=
			(t & Reflex::Pointer::MOUSE_LEFT   ? 1 : 0) +
			(t & Reflex::Pointer::MOUSE_RIGHT  ? 1 : 0) +
			(t & Reflex::Pointer::MOUSE_MIDDLE ? 1 : 0);
	});
	return nbuttons;
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


@implementation NativeWindow

	{
		Reflex::Window *pwindow, *ptr_for_rebind;
		OpenGLView* view;
		NSTimer* timer;
		int update_count;
		int clicking_count;
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
		clicking_count  = 0;
		pointer_id      = 0;

		[self setDelegate: self];
		[self setupContentView];
		[self startTimer];

		return self;
	}

	- (void) dealloc
	{
		assert(!pwindow);

		if (view) [view release];

		[super dealloc];
	}

	- (void) bind: (Reflex::Window*) window
	{
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

	- (BOOL) windowShouldClose: (id) sender
	{
		Reflex::Window* win = self.window;
		if (!win) return YES;

		win->close();
		return NO;
	}

	- (void) windowWillClose: (NSNotification*) notification
	{
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

		if (clicking_count == 0) ++pointer_id;

		Reflex::NativePointerEvent e(event, view, pointer_id, Reflex::Pointer::DOWN);

		if (e[0].position().y < 0)
		{
			// ignore mouseDown event since the mouseUp event to the window title bar
			// will not come and will break clicking_count.
			return;
		}

		[self attachAndUpdatePrevPointer: &e];

		clicking_count += count_mouse_buttons(e);

		Window_call_pointer_event(win, &e);
	}

	- (void) mouseUp: (NSEvent*) event
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		Reflex::NativePointerEvent e(event, view, pointer_id, Reflex::Pointer::UP);
		[self attachAndUpdatePrevPointer: &e];

		clicking_count -= count_mouse_buttons(e);
		if (clicking_count == 0)
			++pointer_id;
		else if (clicking_count < 0)
			return;//Reflex::invalid_state_error(__FILE__, __LINE__);

		Window_call_pointer_event(win, &e);
	}

	- (void) mouseDragged: (NSEvent*) event
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		Reflex::NativePointerEvent e(event, view, pointer_id, Reflex::Pointer::MOVE);
		[self attachAndUpdatePrevPointer: &e];

		Window_call_pointer_event(win, &e);
	}

	- (void) mouseMoved: (NSEvent*) event
	{
		Reflex::Window* win = self.window;
		if (!win) return;

		Reflex::NativePointerEvent e(event, view, pointer_id, Reflex::Pointer::MOVE);
		[self attachAndUpdatePrevPointer: &e];

		Window_call_pointer_event(win, &e);
	}

	- (void) attachAndUpdatePrevPointer: (Reflex::PointerEvent*) e
	{
		assert(e->size() == 1);

		Reflex::Pointer& pointer = Reflex::PointerEvent_pointer_at(e, 0);
		if (prev_pointer)
			Reflex::Pointer_set_prev(&pointer, &prev_pointer);

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
