// -*- objc -*-
#include "application.h"


#import <AppKit/NSApplication.h>
#include "reflex/exception.h"
#include "reflex/debug.h"
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

		if (!app.isRunning)
			[app run];
		else
			[delegate callOnStart];
	}

	void
	Application::quit ()
	{
		[NSApp terminate: nil];
	}

	void
	Application::on_start (Event* e)
	{
	}

	void
	Application::on_quit (Event* e)
	{
	}

	void
	Application::on_motion (MotionEvent* e)
	{
	}

	void
	Application::on_preference (Event* e)
	{
	}

	void
	Application::on_about (Event* e)
	{
		[NSApp orderFrontStandardAboutPanel: nil];
	}

	Application::operator bool () const
	{
		return true;
	}


}// Reflex
