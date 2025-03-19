// -*- objc -*-
#include "reflex/reflex.h"


#import <Cocoa/Cocoa.h>
#include "reflex/exception.h"
#include "event.h"


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

		init_game_controllers();
	}

	void
	fin ()
	{
		fin_game_controllers();

		if (!global::pool)
			reflex_error(__FILE__, __LINE__, "not initialized.");

		[global::pool release];
		global::pool = nil;
	}


}// Reflex
