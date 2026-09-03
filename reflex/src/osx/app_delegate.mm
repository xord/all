// -*- objc -*-
#import "app_delegate.h"


#include <assert.h>
#import <Cocoa/Cocoa.h>
#include "reflex/event.h"
#include "reflex/exception.h"
#include "../application.h"
#include "../rays.h"
#include "menu.h"


static Reflex::Menu::Ref
create_menu (
	const char* label, const char* name, SEL action = NULL,
	Reflex::KeyCode key = Reflex::KEY_NONE, uint modifiers = Reflex::MOD_COMMAND)
{
	Reflex::Menu* item = new Reflex::Menu(label);
	item->set_name(name);
	if (key != Reflex::KEY_NONE) item->set_shortcut(key, modifiers);
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
	app->add_child(create_menu("Preferences", "preferences", @selector(showPreference), KEY_COMMA));
	app->add_child(create_sep());
	app->add_child(services.get());
	app->add_child(create_sep());
	app->add_child(create_menu(("Hide" + name).c_str(), "hide", @selector(hide:), KEY_H));
	app->add_child(create_menu(
		"Hide Others", "hide_others", @selector(hideOtherApplications:),
		KEY_H, MOD_OPTION | MOD_COMMAND));
	app->add_child(create_menu("ShowAll", "show_all", @selector(unhideAllApplications:)));
	app->add_child(create_sep());
	app->add_child(create_menu(("Quit" + name).c_str(), "quit", @selector(quit), KEY_Q));

	[NSApp setServicesMenu: Menu_get_nssubmenu(services)];
	if ([NSApp respondsToSelector: @selector(setAppleMenu:)])
		[NSApp performSelector: @selector(setAppleMenu:) withObject: Menu_get_nssubmenu(app)];

	return app;
}

static Reflex::Menu::Ref
create_window_menu ()
{
	using namespace Reflex;

	Reflex::Menu::Ref win = create_menu("Window", "window");

	win->add_child(create_menu("Minimize", "minimize", @selector(performMiniaturize:), KEY_M));
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
		NSStatusItem* status_item;
		bool launched;
	}

	- (id) init
	{
		self = [super init];
		if (!self) return nil;

		application = NULL;
		status_item = nil;
		launched    = false;

		return self;
	}

	- (void) dealloc
	{
		assert(!application);

		[self clearStatusItem];

		[super dealloc];
	}

	- (void) clearStatusItem
	{
		if (!status_item) return;

		[NSStatusBar.systemStatusBar removeStatusItem: status_item];
		[status_item release];
		status_item = nil;
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
		if (!application)
			return YES;

		Reflex::Event e;
		Application_call_start_event(application, &e);

		if (e.is_blocked()) [self quit];
		return !e.is_blocked();
	}

	- (BOOL) isLaunched
	{
		return launched;
	}

	- (void) updateStatusItem
	{
		Reflex::Menu* menu = application ? application->background_menu() : NULL;
		if (!menu && application && application->background())
			menu = application->menu();
		if (!menu)
			return [self clearStatusItem];

		if (!status_item)
		{
			status_item =
				[[NSStatusBar.systemStatusBar statusItemWithLength: NSVariableStatusItemLength]
					retain];
		}

		NSImage* image =
			menu->image() ? Rays::Bitmap_get_nsimage(menu->image().bitmap()) : nil;
		[image setTemplate: YES];

		NSString* title = @"";
		if (!image)
		{
			Reflex::String label     = menu->label();
			if (label.empty()) label = application->name();
			title = !label.empty()
				?	[NSString stringWithUTF8String: label]
				:	NSProcessInfo.processInfo.processName;
		}

		status_item.button.image = image;
		status_item.button.title = title;
		status_item.menu         = Reflex::Menu_get_nssubmenu(menu);
	}

	- (void) quit
	{
		if (application)
			Application_call_quit(application);
		else
			[NSApp terminate: nil];
	}

	- (void) showPreference
	{
		if (!application) return;

		Reflex::Event e;
		Application_call_preference_event(application, &e);
	}

	- (void) showAbout
	{
		if (application)
		{
			Reflex::Event e;
			Application_call_about_event(application, &e);
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
		if (application)
			Application_set_background(application, application->background());

		launched = true;
		[self callOnStart];
	}

	- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication*) application
	{
		Reflex::Application* app = self->application;
		if (!app) return NSTerminateNow;

		if (app->self->running && !self.isQuitBySystem)
		{
			Application_call_quit(app);
			return NSTerminateCancel;
		}

		Reflex::Event e;
		Application_call_quit_event(app, &e);
		if (e.is_blocked()) return NSTerminateCancel;

		return NSTerminateNow;
	}

	- (BOOL) isQuitBySystem
	{
		// log out, shut down and restart put a reason on the quit event,
		// while a quit from the dock or a script comes without one
		NSAppleEventDescriptor* event =
			NSAppleEventManager.sharedAppleEventManager.currentAppleEvent;
		return
			event &&
			event.eventClass == kCoreEventClass &&
			event.eventID    == kAEQuitApplication &&
			[event attributeDescriptorForKeyword: kAEQuitReason];
	}

	- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication*) application
	{
		if (Application_should_quit(self->application))
			[self quit];
		return NO;
	}

	- (void) applicationWillTerminate: (NSNotification*) notification
	{
		if (application)
			Application_cleanup(application);

		[self unbind];
	}

@end// ReflexAppDelegate
