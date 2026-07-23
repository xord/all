// -*- objc -*-
#import "app_delegate.h"


#include <assert.h>
#import <Cocoa/Cocoa.h>
#include "reflex/event.h"
#include "reflex/exception.h"
#include "menu.h"


static Reflex::Menu::Ref
create_menu (
	const char* label, const char* name, SEL action = NULL,
	const char* key = NULL, uint modifiers = Reflex::MOD_COMMAND)
{
	Reflex::Menu* item = new Reflex::Menu(label);
	item->set_name(name);
	if (key) item->set_shortcut(key, modifiers);
	Reflex::Menu_set_native_action(item, action);
	return item;
}

static Reflex::Menu::Ref
create_sep ()
{
	return new Reflex::Menu("-");
}

static Reflex::Menu::Ref
create_application_menu (Reflex::Application* application)
{
	using namespace Reflex;

	String name = application->name();
	if (!name.empty()) name = " " + name;

	Menu::Ref app      = create_menu("Application", "application");
	Menu::Ref services = create_menu("Services",    "services");

	app->add_child(create_menu(("About" + name).c_str(), "about", @selector(showAbout)));
	app->add_child(create_sep());
	app->add_child(create_menu("Preferences", "preferences", @selector(showPreference), ","));
	app->add_child(create_sep());
	app->add_child(services.get());
	app->add_child(create_sep());
	app->add_child(create_menu(("Hide" + name).c_str(), "hide", @selector(hide:), "h"));
	app->add_child(create_menu(
		"Hide Others", "hide_others", @selector(hideOtherApplications:),
		"h", MOD_OPTION | MOD_COMMAND));
	app->add_child(create_menu("ShowAll", "show_all", @selector(unhideAllApplications:)));
	app->add_child(create_sep());
	app->add_child(create_menu(("Quit" + name).c_str(), "quit", @selector(quit), "q"));

	[NSApp setServicesMenu: Menu_get_nssubmenu(services)];
	if ([NSApp respondsToSelector: @selector(setAppleMenu:)])
		[NSApp performSelector: @selector(setAppleMenu:) withObject: Menu_get_nssubmenu(app)];

	return app;
}

static Reflex::Menu::Ref
create_window_menu ()
{
	Reflex::Menu::Ref win = create_menu("Window", "window");

	win->add_child(create_menu("Minimize", "minimize", @selector(performMiniaturize:), "m"));
	win->add_child(create_menu("Zoom", "zoom", @selector(performZoom:)));
	win->add_child(create_sep());
	win->add_child(create_menu(
		"Bring All to Front", "bring_all_to_front", @selector(arrangeInFront:)));

	[NSApp setWindowsMenu: Menu_get_nssubmenu(win)];

	return win;
}


@implementation ReflexAppDelegate

	{
		Reflex::Application* application;
		bool started;
	}

	- (id) init
	{
		self = [super init];
		if (!self) return nil;

		application = NULL;
		started     = false;

		return self;
	}

	- (void) dealloc
	{
		assert(!application);

		[super dealloc];
	}

	- (void) bind: (Reflex::Application*) app
	{
		if (!app)
			Reflex::argument_error(__FILE__, __LINE__);

		Reflex::ApplicationData& data = Reflex::Application_get_data(app);
		if (data.delegate)
			Reflex::invalid_state_error(__FILE__, __LINE__);

		data.delegate = [self retain];
		app->retain();

		application = app;
	}

	- (void) unbind
	{
		if (!application) return;

		Reflex::ApplicationData& data = Reflex::Application_get_data(application);
		if (data.delegate)
		{
			[data.delegate release];
			data.delegate = nil;
		}

		application->release();
		application = NULL;
	}

	- (BOOL) callOnStart
	{
		if (!application || started)
			return YES;

		Reflex::Event e;
		Application_call_start(application, &e);
		started = true;

		if (e.is_blocked()) [self quit];
		return !e.is_blocked();
	}

	- (void) quit
	{
		if (application)
			application->quit();
		else
			[NSApp terminate: nil];
	}

	- (void) showPreference
	{
		if (!application) return;

		Reflex::Event e;
		application->on_preference(&e);
	}

	- (void) showAbout
	{
		if (application)
		{
			Reflex::Event e;
			application->on_about(&e);
		}
		else
			[NSApp orderFrontStandardAboutPanel: nil];
	}

	- (void) applicationWillFinishLaunching: (NSNotification*) notification
	{
		if (!application || [NSApp mainMenu]) return;

		Reflex::Menu::Ref menu = new Reflex::Menu();
		menu->add_child(create_application_menu(application));
		menu->add_child(create_window_menu());
		application->set_menu(menu);
	}

	- (void) applicationDidFinishLaunching: (NSNotification*) notification
	{
		[NSApp setActivationPolicy: NSApplicationActivationPolicyRegular];
		[NSApp activateIgnoringOtherApps: YES];

		[self callOnStart];
	}

	- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication*) application
	{
		if (self->application)
		{
			Reflex::Event e;
			Application_call_quit(self->application, &e);
			if (e.is_blocked()) return NSTerminateCancel;
		}

		return NSTerminateNow;
	}

	- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication*) application
	{
		return YES;
	}

	- (void) applicationWillTerminate: (NSNotification*) notification
	{
		[self unbind];
	}

@end// ReflexAppDelegate
