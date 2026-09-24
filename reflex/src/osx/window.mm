// -*- objc -*-
#include "window.h"


#import <Cocoa/Cocoa.h>
#include "reflex/exception.h"
#include "menu.h"
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
		Xot::update_flag(
			&styleMask, NSWindowStyleMaskClosable,
			Xot::has_flag(flags, Window::FLAG_CLOSABLE));
		Xot::update_flag(
			&styleMask, NSWindowStyleMaskMiniaturizable,
			Xot::has_flag(flags, Window::FLAG_MINIMIZABLE));
		Xot::update_flag(
			&styleMask, NSWindowStyleMaskResizable,
			Xot::has_flag(flags, Window::FLAG_RESIZABLE));
		Xot::update_flag(
			&styleMask, NSWindowStyleMaskFullSizeContentView,
			!Xot::has_flag(flags, Window::FLAG_TITLEBAR_BACKGROUND));

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

	uint
	Window_default_flags ()
	{
		return
			Window::FLAG_CLOSABLE            |
			Window::FLAG_MINIMIZABLE         |
			Window::FLAG_RESIZABLE           |
			Window::FLAG_TITLEBAR_BUTTONS    |
			Window::FLAG_TITLEBAR_BACKGROUND |
			Window::FLAG_SHADOW;
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
	Window_set_frame (Window* window, coord x, coord y, coord w, coord h)
	{
		NativeWindow* native = get_native(window);

		NSRect r   = [native frameRectForContentRect: NSMakeRect(x, y, w, h)];
		r.origin.y = primary_screen_height() - (y + h);

		[native setFrame: r display: NO animate: NO];
	}

	Bounds
	Window_get_frame (const Window& window)
	{
		NativeWindow* native = get_native(&window);

		NSRect r   = [native contentRectForFrameRect: native.frame];
		r.origin.y = primary_screen_height() - (r.origin.y + r.size.height);

		return Bounds(r.origin.x, r.origin.y, r.size.width, r.size.height);
	}

	void
	Window_set_menu (Window* window, Menu* menu)
	{
		NativeWindow* native = get_native(window);
		if (!native) return;

		if (native.isMainWindow)
			Menu_apply_to_main_menu(menu);
	}

	Screen
	Window_get_screen (const Window& window)
	{
		Screen s;
		NSScreen* screen = get_native(&window).screen;
		if (screen) Screen_initialize(&s, screen);
		return s;
	}

	void
	Window_set_flags (Window* window, uint flags)
	{
		if (Xot::has_flag(flags, Window::FLAG_PORTRAIT))
			argument_error(__FILE__, __LINE__, "FLAG_PORTRAIT is not supported");

		if (Xot::has_flag(flags, Window::FLAG_LANDSCAPE))
			argument_error(__FILE__, __LINE__, "FLAG_LANDSCAPE is not supported");

		NativeWindow* native        = get_native(window);
		NSWindowStyleMask styleMask =
			Window_make_style_mask(flags, native.styleMask);

		if (styleMask != native.styleMask)
		{
			NSRect content   = [native contentRectForFrameRect: native.frame];
			native.styleMask = styleMask;
			[native setFrame: [native frameRectForContentRect: content] display: YES];
		}

		bool buttons    = Xot::has_flag(flags, Window::FLAG_TITLEBAR_BUTTONS);
		bool background = Xot::has_flag(flags, Window::FLAG_TITLEBAR_BACKGROUND);
		[native setTitlebarButtonsVisible:    buttons];
		[native setTitlebarBackgroundVisible: background];
		[native setTitlebarContainerVisible:  buttons || background];

		NSWindowCollectionBehavior behavior = native.collectionBehavior;
		if (Xot::has_flag(flags, Window::FLAG_UNLISTED))
		{
			behavior &= ~NSWindowCollectionBehaviorManaged;
			behavior |=  NSWindowCollectionBehaviorTransient;
		}
		else
		{
			behavior &= ~NSWindowCollectionBehaviorTransient;
			behavior |=  NSWindowCollectionBehaviorManaged;
		}
		native.collectionBehavior = behavior;

		native.hasShadow = Xot::has_flag(flags, Window::FLAG_SHADOW);

		[native setBackgroundTransparent: Xot::has_flag(flags, Window::FLAG_TRANSPARENT)];

		if (native.hasFullScreenFlag != Xot::has_flag(flags, Window::FLAG_FULLSCREEN))
			[native toggleFullScreen: native];

		if (Xot::has_flag(flags, Window::FLAG_ALWAYS_ON_TOP))
			native.level = NSFloatingWindowLevel;
		else if (Xot::has_flag(flags, Window::FLAG_ALWAYS_ON_BOTTOM))
			native.level = NSNormalWindowLevel - 1;
		else
			native.level = NSNormalWindowLevel;
	}

	float
	Window_get_pixel_density (const Window& window)
	{
		return get_native(&window).backingScaleFactor;
	}

	void
	Window_set_pointer_through (Window* window, bool through)
	{
		get_native(window).ignoresMouseEvents = through ? YES : NO;
	}

	static bool
	is_covered_by_another_window (NativeWindow* native, NSPoint screen_pos)
	{
		// only a window that takes mouse events counts as covering. when
		// the frontmost window at the point is also the frontmost behind
		// this window, nothing sits between them, so nothing is in front
		// of this window. this holds while the window ignores mouse events
		// too, since the hit test then skips the window itself

		NSInteger hit = [NSWindow
			windowNumberAtPoint: screen_pos
			belowWindowWithWindowNumber: 0];
		if (hit == 0 || hit == native.windowNumber)
			return false;

		NSInteger behind = [NSWindow
			windowNumberAtPoint: screen_pos
			belowWindowWithWindowNumber: native.windowNumber];
		return hit != behind;
	}

	bool
	Window_is_pointer_over_and_uncovered (Point* position, const Window& window)
	{
		NativeWindow* native = get_native(&window);
		NSPoint screen_pos   = [NSEvent mouseLocation];
		if (!NSPointInRect(screen_pos, native.frame))
			return false;
		if (is_covered_by_another_window(native, screen_pos))
			return false;

		NSRect screen_rect = NSMakeRect(screen_pos.x, screen_pos.y, 0, 0);
		NSRect window_rect = [native convertRectFromScreen: screen_rect];
		NSView* view       = native.contentView;
		NSPoint view_pos   = [view convertPoint: window_rect.origin fromView: nil];
		position->reset(view_pos.x, view.bounds.size.height - view_pos.y);
		return true;
	}


}// Reflex
