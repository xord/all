// -*- objc -*-
#include "../opengl.h"


#include <vector>
#import <OpenGLES/EAGL.h>


namespace Rays
{


	void
	OpenGL_set_context (Context context)
	{
		[EAGLContext setCurrentContext: (EAGLContext*) context];
	}

	Context
	OpenGL_get_context ()
	{
		return [EAGLContext currentContext];
	}


	Context
	get_offscreen_context ()
	{
		static Context context = NULL;
		if (!context)
			context = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES3];
		return context;
	}


}// Rays
