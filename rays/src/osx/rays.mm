// -*- objc -*-
#include "rays/rays.h"


#import <Foundation/Foundation.h>
#include "rays/exception.h"
#include "../opengl.h"


namespace Rays
{


	namespace global
	{


		static NSAutoreleasePool* pool = nil;


	}// global


	void
	init ()
	{
		if (global::pool)
			rays_error(__FILE__, __LINE__, "Rays::init(): already initialized.");

		global::pool = [[NSAutoreleasePool alloc] init];

		OpenGL_init();
	}

	void
	fin ()
	{
		if (!global::pool)
			rays_error(__FILE__, __LINE__, "Rays::fin(): not initialized.");

		OpenGL_fin();

		[global::pool release];
		global::pool = nil;
	}


}// Rays
