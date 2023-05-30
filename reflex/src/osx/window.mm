// -*- objc -*-
#include "window.h"


#import <Cocoa/Cocoa.h>
#include "reflex/exception.h"
#include "screen.h"
#import "native_window.h"


@interface NativeWindow (Bind)
	- (void) bind: (Reflex::Window*) window;
@end


namespace Reflex
{


	WindowData&
	Window_get_data (Window* window)
	{
		if (!window)
			argument_error(__FILE__, __LINE__);

		return (WindowData&) *window->self;
	}

	const WindowData&
	Window_get_data (const Window* window)
	{
		return Window_get_data(const_cast<Window*>(window));
	}

	NSWindowStyleMask
	Window_make_style_mask (uint flags, NSWindowStyleMask styleMask)
	{
		if (Xot::has_flag(flags, Window::FLAG_CLOSABLE))
			styleMask |=  NSWindowStyleMaskClosable;
		else
			styleMask &= ~NSWindowStyleMaskClosable;

		if (Xot::has_flag(flags, Window::FLAG_MINIMIZABLE))
			styleMask |=  NSWindowStyleMaskMiniaturizable;
		else
			styleMask &= ~NSWindowStyleMaskMiniaturizable;

		if (Xot::has_flag(flags, Window::FLAG_RESIZABLE))
			styleMask |=  NSWindowStyleMaskResizable;
		else
			styleMask &= ~NSWindowStyleMaskResizable;

		return styleMask;
	}

	static NativeWindow*
	get_native (const Window* window)
	{
		NativeWindow* p = Window_get_data(const_cast<Window*>(window)).native;
		if (!p)
			invalid_state_error(__FILE__, __LINE__);

		return p;
	}


	Window::Data*
	Window_create_data ()
	{
		return new WindowData();
	}

	void
	Window_initialize (Window* window)
	{
		[[[NativeWindow alloc] init] bind: window];
	}

	void
	Window_show (Window* window)
	{
		[get_native(window) makeKeyAndOrderFront: nil];
	}

	void
	Window_hide (Window* window)
	{
		NativeWindow* native = get_native(window);
		[native orderOut: native];
	}

	void
	Window_close (Window* window)
	{
		[get_native(window) close];
	}

	void
	Window_set_title (Window* window, const char* title)
	{
		if (!title)
			argument_error(__FILE__, __LINE__);

		[get_native(window) setTitle: [NSString stringWithUTF8String: title]];
	}

	const char*
	Window_get_title (const Window& window)
	{
		const WindowData& data = Window_get_data(&window);

		NSString* s = [get_native(&window) title];
		data.title_tmp = s ? [s UTF8String] : "";
		return data.title_tmp.c_str();
	}

	void
	Window_set_frame (Window* window, coord x, coord y, coord width, coord height)
	{
		NSRect frame =
			[NativeWindow frameRectForContentRect: NSMakeRect(x, y, width, height)];
		[get_native(window) setFrame: frame display: NO animate: NO];
	}

	Bounds
	Window_get_frame (const Window& window)
	{
		NativeWindow* native = get_native(&window);
		NSRect r = [native contentRectForFrameRect: [native frame]];
		return Bounds(r.origin.x, r.origin.y, r.size.width, r.size.height);
	}

	void
	Window_set_flags (Window* window, uint flags)
	{
		NativeWindow* native        = get_native(window);
		NSWindowStyleMask styleMask =
			Window_make_style_mask(window->self->flags, native.styleMask);

		if (styleMask != native.styleMask)
			native.styleMask = styleMask;
	}

	Screen
	Window_get_screen (const Window& window)
	{
		Screen s;
		NativeWindow* native = get_native(&window);
		if (native && native.screen) Screen_initialize(&s, native.screen);
		return s;
	}

	float
	Window_get_pixel_density (const Window& window)
	{
		return get_native(&window).backingScaleFactor;
	}


}// Reflex
