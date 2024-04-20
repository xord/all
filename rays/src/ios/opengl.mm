// -*- objc -*-
#include "../opengl.h"


#import <OpenGLES/EAGL.h>
#include "rays/rays.h"
#include "rays/exception.h"


namespace Rays
{


	static EAGLContext*
	get_opengl_offscreen_context ()
	{
		static EAGLContext* context = nil;
		if (!context)
			context = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES3];
		return context;
	}


	void
	OpenGL_init ()
	{
		[EAGLContext setCurrentContext: get_opengl_offscreen_context()];
	}

	void
	OpenGL_fin ()
	{
	}


	Context
	get_offscreen_context ()
	{
		return get_opengl_offscreen_context();
	}


}// Rays
