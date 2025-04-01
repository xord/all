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
	Application::on_about (Event* e)
	{
	}


}// Reflex
