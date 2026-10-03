// -*- objc -*-
#include "reflex/reflex.h"


#import <Cocoa/Cocoa.h>
#include "reflex/exception.h"
#include "../vk.h"
#include "application.h"


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

	void
	alert (const char* message, const char* title)
	{
		if (!message)
			argument_error(__FILE__, __LINE__);

		Application_activate();

		NSAlert* alert = [[[NSAlert alloc] init] autorelease];
		NSString* text = [NSString stringWithUTF8String: message];
		if (title && *title)
		{
			alert.messageText     = [NSString stringWithUTF8String: title];
			alert.informativeText = text;
		}
		else
			alert.messageText = text;

		[alert runModal];
	}


}// Reflex
