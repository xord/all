// -*- objc -*-
#include "application.h"


#import <AppKit/NSApplication.h>
#include "reflex/exception.h"
#include "reflex/debug.h"
#import "app_delegate.h"


namespace Reflex
{


	namespace global
	{

		static Application* instance = NULL;

	}// global


	Application*
	app ()
	{
		return global::instance;
	}


	Application::Application ()
	{
		if (global::instance)
			reflex_error(__FILE__, __LINE__, "multiple application instances.");

		global::instance = this;
	}

	Application::~Application ()
	{
		global::instance = NULL;
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
	Application::set_name (const char* name)
	{
		if (!name)
			argument_error(__FILE__, __LINE__);

		self->name = name;
	}

	const char*
	Application::name () const
	{
		return self->name.c_str();
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

	bool
	Application::operator ! () const
	{
		return !operator bool();
	}


	Application::Data::Data ()
	:	delegate(nil)
	{
	}


}// Reflex
