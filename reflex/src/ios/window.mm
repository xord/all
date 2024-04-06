// -*- objc -*-
#include "window.h"


#import <UIKit/UIKit.h>
#include "reflex/exception.h"
#include "screen.h"
#import "view_controller.h"


@interface ReflexViewController (Bind)
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

	static ReflexViewController*
	get_vc (const Window* window)
	{
		ReflexViewController* p =
			Window_get_data(const_cast<Window*>(window)).view_controller;
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
			Window::FLAG_RESIZABLE |
			Window::FLAG_PORTRAIT  |
			Window::FLAG_LANDSCAPE;
	}

	void
	Window_initialize (Window* window)
	{
		ReflexViewController* vc = ReflexViewController_get_create_fun()();
		if (!vc)
			reflex_error(__FILE__, __LINE__);

		[vc bind: window];
	}

	static UIWindow*
	get_window ()
	{
		UIApplication* app = UIApplication.sharedApplication;
		if (app.keyWindow)
			return app.keyWindow;
		else
		{
			UIWindow* win =
				[[UIWindow alloc] initWithFrame: UIScreen.mainScreen.bounds];
			[win makeKeyAndVisible];
			return win;
		}
	}

	void
	Window_show (Window* window)
	{
		UIWindow* win            = get_window();
		ReflexViewController* vc = get_vc(window);

		if (!win.rootViewController)
			win.rootViewController = vc;
		else
			ReflexViewController_get_show_fun()(win.rootViewController, vc);
	}

	void
	Window_hide (Window* window)
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	void
	Window_close (Window* window)
	{
	}

	void
	Window_set_title (Window* window, const char* title)
	{
		if (!title)
			argument_error(__FILE__, __LINE__);

		ReflexViewController* vc = get_vc(window);
		NSString* titleStr       = [NSString stringWithUTF8String: title];

		if ([titleStr isEqualToString: vc.title])
			return;

		vc.title = titleStr;
		[vc titleDidChange];
	}

	const char*
	Window_get_title (const Window& window)
	{
		return [get_vc(&window).title UTF8String];
	}

	void
	Window_set_frame (Window* window, coord x, coord y, coord width, coord height)
	{
		//not_implemented_error(__FILE__, __LINE__);
	}

	Bounds
	Window_get_frame (const Window& window)
	{
		CGRect b = get_vc(&window).reflexView.bounds;
		return Bounds(b.origin.x, b.origin.y, b.size.width, b.size.height);
	}

	static UIScreen*
	get_screen (const Window& window)
	{
		UIWindow* w = get_vc(&window).view.window;
		if (@available(iOS 13.0, *))
			return w.windowScene.screen;
		else
			return w.screen;
	}

	Screen
	Window_get_screen (const Window& window)
	{
		Screen s;
		UIScreen* screen = get_screen(window);
		Screen_initialize(&s, screen ? screen : UIScreen.mainScreen);
		return s;
	}

	static UIInterfaceOrientationMask g_orientation_mask =
		UIInterfaceOrientationMaskAll;

	static UIInterfaceOrientation
	current_orientation (UIViewController* vc)
	{
		switch (UIDevice.currentDevice.orientation)
		{
			case UIDeviceOrientationPortrait:           return UIInterfaceOrientationPortrait;
			case UIDeviceOrientationLandscapeLeft:      return UIInterfaceOrientationLandscapeLeft;
			case UIDeviceOrientationLandscapeRight:     return UIInterfaceOrientationLandscapeRight;
			case UIDeviceOrientationPortraitUpsideDown: return UIInterfaceOrientationPortraitUpsideDown;
			default: return vc.preferredInterfaceOrientationForPresentation;
		}
	}

	static UIInterfaceOrientationMask
	to_mask (UIInterfaceOrientation orientation)
	{
		switch (orientation)
		{
			case UIInterfaceOrientationPortrait:           return UIInterfaceOrientationMaskPortrait;
			case UIInterfaceOrientationLandscapeLeft:      return UIInterfaceOrientationMaskLandscapeLeft;
			case UIInterfaceOrientationLandscapeRight:     return UIInterfaceOrientationMaskLandscapeRight;
			case UIInterfaceOrientationPortraitUpsideDown: return UIInterfaceOrientationMaskPortraitUpsideDown;
			default:                                       return 0;
		}
	}

	static UIInterfaceOrientation
	get_proper_orientation (UIViewController* vc, UIInterfaceOrientationMask mask)
	{
		UIInterfaceOrientation current = current_orientation(vc);
		if (to_mask(current)                             & mask) return current;
		if (UIInterfaceOrientationMaskPortrait           & mask) return UIInterfaceOrientationPortrait;
		if (UIInterfaceOrientationMaskLandscapeLeft      & mask) return UIInterfaceOrientationLandscapeLeft;
		if (UIInterfaceOrientationMaskLandscapeRight     & mask) return UIInterfaceOrientationLandscapeRight;
		if (UIInterfaceOrientationMaskPortraitUpsideDown & mask) return UIInterfaceOrientationPortraitUpsideDown;
		return UIInterfaceOrientationPortrait;
	}

	static void
	update_orientation_mask (UIViewController* vc, UIInterfaceOrientationMask mask)
	{
		if (!vc) return;

		if (@available(iOS 16.0, *))
			[vc setNeedsUpdateOfSupportedInterfaceOrientations];
		else
		{
			[UIDevice.currentDevice
				setValue: [NSNumber numberWithInteger: get_proper_orientation(vc, mask)]
				forKey:   @"orientation"];
			[UIViewController attemptRotationToDeviceOrientation];
		}
	}

	void
	Window_set_orientation_mask (UIViewController* vc, UIInterfaceOrientationMask mask)
	{
		if (mask == g_orientation_mask) return;

		g_orientation_mask = mask;
		update_orientation_mask(vc, mask);
	}

	UIInterfaceOrientationMask
	Window_get_orientation_mask ()
	{
		return g_orientation_mask;
	}

	static UIInterfaceOrientationMask
	flags_to_orientation_mask (uint flags)
	{
		UIInterfaceOrientationMask mask = 0;

		if (flags & Window::FLAG_PORTRAIT)
		{
			mask |=
				UIInterfaceOrientationMaskPortrait |
				UIInterfaceOrientationPortraitUpsideDown;
		}

		if (flags & Window::FLAG_LANDSCAPE)
			mask |= UIInterfaceOrientationMaskLandscape;

		return mask != 0 ? mask : UIInterfaceOrientationMaskAll;
	}

	void
	Window_set_flags (Window* window, uint flags)
	{
		if (Xot::has_flag(flags, Window::FLAG_CLOSABLE))
			argument_error(__FILE__, __LINE__, "FLAG_CLOSABLE is not supported");

		if (Xot::has_flag(flags, Window::FLAG_MINIMIZABLE))
			argument_error(__FILE__, __LINE__, "FLAG_MINIMIZABLE is not supported");

		Window_set_orientation_mask(
			get_vc(window),
			flags_to_orientation_mask(flags & (Window::FLAG_PORTRAIT | Window::FLAG_LANDSCAPE)));
	}

	float
	Window_get_pixel_density (const Window& window)
	{
		return UIScreen.mainScreen.nativeScale;
	}


}// Reflex
