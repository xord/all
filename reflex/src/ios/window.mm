// -*- objc -*-
#include "window.h"


#include "reflex/exception.h"
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

	void
	Window_set_resizable (Window* window, bool state)
	{
		//not_implemented_error(__FILE__, __LINE__);
	}

	bool
	Window_is_resizable (const Window& window)
	{
		return false;
	}

	float
	Window_get_pixel_density (const Window& window)
	{
		return UIScreen.mainScreen.scale;
	}


}// Reflex
