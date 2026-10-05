// -*- objc -*-
#include "reflex/reflex.h"


#import <Cocoa/Cocoa.h>
#include "reflex/exception.h"
#include "../vk.h"


namespace Reflex
{


	namespace global
	{

		static NSAutoreleasePool* pool = nil;

	}// global


	void
	init ()
	{
		if (global::pool)
			reflex_error(__FILE__, __LINE__, "already initialized.");

		global::pool = [[NSAutoreleasePool alloc] init];
	}

	void
	fin ()
	{
		if (!global::pool)
			reflex_error(__FILE__, __LINE__, "not initialized.");

		[global::pool release];
		global::pool = nil;
	}

	static void
	activate_app ()
	{
		NSApplication* app = NSApplication.sharedApplication;
		if (app.activationPolicy == NSApplicationActivationPolicyProhibited)
			[app setActivationPolicy: NSApplicationActivationPolicyRegular];

		[app activateIgnoringOtherApps: YES];
	}

	void
	alert (const char* message, const char* title)
	{
		if (!message)
			argument_error(__FILE__, __LINE__);

		activate_app();

		NSAlert* alert = [[[NSAlert alloc] init] autorelease];
		NSString* text = [NSString stringWithUTF8String: message];
		if (title && *title)
		{
			alert.messageText     = [NSString stringWithUTF8String: title];
			alert.informativeText = text;
		}
		else
			alert.messageText = text;

		// in front of the other apps once runModal shows it, as macOS 14 or
		// later lets no app launched from a terminal take the focus from it
		[alert.window
			performSelector: @selector(orderFrontRegardless)
			withObject: nil afterDelay: 0 inModes: @[NSModalPanelRunLoopMode]];

		[alert runModal];
	}


}// Reflex
