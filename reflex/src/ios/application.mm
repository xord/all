// -*- objc -*-
#include "application.h"


#include "reflex/exception.h"
#import "app_delegate.h"


extern "C" {
	char*** _NSGetArgv ();
	int*    _NSGetArgc ();
}


@interface ReflexAppDelegate (Bind)
	- (void) bind: (Reflex::Application*) application;
	- (BOOL) callOnStart;
@end


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

	void
	Application::start ()
	{
		UIApplication* app                 = UIApplication.sharedApplication;
		id<UIApplicationDelegate> delegate = app.delegate;
		if (!delegate)
		{
			UIApplicationMain(*_NSGetArgc(), *_NSGetArgv(), nil, @"ReflexAppDelegate");
			return;
		}

		if ([delegate isKindOfClass: ReflexAppDelegate.class])
		{
			ReflexAppDelegate* reflex_delegate = (ReflexAppDelegate*) delegate;
			[reflex_delegate bind: this];
			[reflex_delegate callOnStart];
		}
	}

	void
	Application::quit ()
	{
		not_implemented_error(__FILE__, __LINE__);
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
