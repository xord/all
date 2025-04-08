// -*- objc -*-
#import "app_delegate.h"


#include <assert.h>
#import <Cocoa/Cocoa.h>
#include "reflex/event.h"
#include "reflex/exception.h"


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

	- (void) applicationDidFinishLaunching: (NSNotification*) notification
	{
		[NSApp setActivationPolicy: NSApplicationActivationPolicyRegular];
		[NSApp activateIgnoringOtherApps: YES];

		if (![self callOnStart])
			return;

		[self setupMenu];
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

	- (BOOL) setupApplicationMenu: (NSMenu*) parent
	{
		if (!application || !parent) return NO;

		NSMenu* menu = [[[NSMenu alloc]
			initWithTitle: @"Application"]
			autorelease];
		if ([NSApp respondsToSelector: @selector(setAppleMenu:)])
			[NSApp performSelector: @selector(setAppleMenu:) withObject: menu];

		NSString* name = !application->self->name.empty() ?
			[NSString stringWithUTF8String: application->self->name.c_str()] : @"";
		if ([name length] > 0)
			name = [@" " stringByAppendingString: name];

		NSMenu* submenu = nil;
		NSMenuItem* item = nil;

		[menu
			addItemWithTitle: [@"About" stringByAppendingString: name]
			action: @selector(showAbout)
			keyEquivalent: @""];

		[menu addItem: [NSMenuItem separatorItem]];

		[menu
			addItemWithTitle: @"Preferences"
			action: @selector(showPreference)
			keyEquivalent: @","];

		[menu addItem: [NSMenuItem separatorItem]];

		item = [menu
			addItemWithTitle: @"Services"
			action: nil
			keyEquivalent: @""];
		submenu = [[[NSMenu alloc] initWithTitle: @"Services"] autorelease];
		[item setSubmenu: submenu];
		[NSApp setServicesMenu: submenu];

		[menu addItem: [NSMenuItem separatorItem]];

		[menu
			addItemWithTitle: [@"Hide" stringByAppendingString: name]
			action: @selector(hide:)
			keyEquivalent: @"h"];

		item = [menu
			addItemWithTitle: @"Hide Others"
			action: @selector(hideOtherApplications:)
			keyEquivalent: @"h"];
		[item setKeyEquivalentModifierMask: NSAlternateKeyMask | NSCommandKeyMask];

		[menu
			addItemWithTitle: @"ShowAll"
			action: @selector(unhideAllApplications:)
			keyEquivalent: @""];

		[menu addItem: [NSMenuItem separatorItem]];

		[menu
			addItemWithTitle: [@"Quit" stringByAppendingString: name]
			action: @selector(quit)
			keyEquivalent: @"q"];

		item =
			[parent addItemWithTitle: @"Application" action: nil keyEquivalent: @""];
		[parent setSubmenu: menu forItem: item];

		return YES;
	}

	- (BOOL) setupWindowMenu: (NSMenu*) parent
	{
		if (!parent) return NO;

		NSMenu* menu = [[[NSMenu alloc]
			initWithTitle: @"Window"]
			autorelease];

		[menu
			addItemWithTitle: @"Minimize"
			action: @selector(performMiniaturize:)
			keyEquivalent: @"m"];

		[menu
			addItemWithTitle: @"Zoom"
			action: @selector(performZoom:)
			keyEquivalent: @""];

		[menu addItem: [NSMenuItem separatorItem]];

		[menu
			addItemWithTitle: @"Bring All to Front"
			action: @selector(arrangeInFront:)
			keyEquivalent: @""];

		NSMenuItem* item =
			[parent addItemWithTitle: @"Window" action: nil keyEquivalent: @""];
		[parent setSubmenu: menu forItem: item];

		[NSApp setWindowsMenu: menu];

		return YES;
	}

	- (BOOL) setupMenu
	{
		if ([NSApp mainMenu]) return NO;

		NSMenu* menu = [[[NSMenu alloc] initWithTitle: @"MainMenu"] autorelease];

		if (
			![self setupApplicationMenu: menu] ||
			![self setupWindowMenu: menu])
		{
			return NO;
		}

		[NSApp setMainMenu: menu];

		return YES;
	}

@end// ReflexAppDelegate
