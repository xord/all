// -*- objc -*-
#include "application.h"


#import <AppKit/AppKit.h>
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "window.h"
#include "menu.h"
#import "native_window.h"
#import "app_delegate.h"


namespace Reflex
{


	Application::Data*
	Application_create_data ()
	{
		return new ApplicationData();
	}

	ApplicationData&
	Application_get_data (Application* app)
	{
		if (!app)
			argument_error(__FILE__, __LINE__);

		return (ApplicationData&) *app->self;
	}

	const ApplicationData&
	Application_get_data (const Application* app)
	{
		return Application_get_data(const_cast<Application*>(app));
	}

	static void
	update_status_item (Application* app)
	{
		[Application_get_data(app).delegate updateStatusItem];
	}

	void
	Application_stop (Application* app)
	{
		[NSApp stop: nil];

		// stop: takes effect only after an event is handled, so post one
		NSEvent* e = [NSEvent
			otherEventWithType: NSEventTypeApplicationDefined
			location: NSZeroPoint modifierFlags: 0 timestamp: 0
			windowNumber: 0 context: nil subtype: 0 data1: 0 data2: 0];
		[NSApp postEvent: e atStart: YES];
	}

	void
	Application_set_menu (Application* app, Menu* menu)
	{
		update_status_item(app);

		for (auto it = app->window_begin(), end = app->window_end(); it != end; ++it)
		{
			Window* win = it->get();
			if (win->menu() && Window_get_data(win).native.isMainWindow)
				return;
		}

		Menu_apply_to_main_menu(menu);
	}

	void
	Application_set_background (Application* app, bool state)
	{
		[NSApp setActivationPolicy: state
			?	NSApplicationActivationPolicyAccessory
			:	NSApplicationActivationPolicyRegular];

		if (!state)
			[NSApp activateIgnoringOtherApps: YES];

		update_status_item(app);
	}

	void
	Application_set_background_menu (Application* app, Menu* menu)
	{
		update_status_item(app);
	}


	ApplicationData::ApplicationData ()
	:	delegate(nil)
	{
	}


	static ReflexAppDelegate*
	setup_app_delegate (NSApplication* app)
	{
		id<NSApplicationDelegate> delegate = app.delegate;
		if (!delegate)
		{
			delegate     = [[[ReflexAppDelegate alloc] init] autorelease];
			app.delegate = delegate;
		}

		if (![delegate isKindOfClass: ReflexAppDelegate.class])
			reflex_error(__FILE__, __LINE__);

		return (ReflexAppDelegate*) delegate;
	}

	void
	Application::start ()
	{
		NSApplication* app          = NSApplication.sharedApplication;
		ReflexAppDelegate* delegate = setup_app_delegate(app);
		[delegate bind: this];

		if (app.isRunning)
		{
			// the host app runs the event loop
			[delegate callOnStart];
			return;
		}

		if (delegate.isLaunched)
		{
			// the app is launched only once, so the later runs start by themselves
			[delegate performSelector: @selector(callOnStart) withObject: nil afterDelay: 0];
		}

		self->started  = false;
		self->quitting = false;
		self->running  = true;
		[app run];
		self->running  = false;

		Application_cleanup(this);
		[delegate unbind];

		Application_throw_exception(this);
	}

	void
	Application::quit ()
	{
		// terminate exits the process even before run, which would take down
		// irb or a test process
		if (!NSApp.isRunning)
			invalid_state_error(__FILE__, __LINE__, "the application is not running.");

		Event e;
		Application_call_quit(this, &e);
		if (e.is_blocked()) return;

		if (self->running)
			Application_stop(this);
		else
			[NSApp terminate: nil];
	}

	void
	Application::on_about (Event* e)
	{
		[NSApp orderFrontStandardAboutPanel: nil];
	}


}// Reflex
