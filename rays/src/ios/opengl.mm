// -*- objc -*-
#include "../opengl.h"


#include <vector>
#import <OpenGLES/EAGL.h>


namespace Rays
{


	struct OpenGLContext : public Context
	{

		using Context::ptr1;
		using Context::ptr2;

	};// OpenGLContext


	void
	OpenGL_init ()
	{
		OpenGL_set_context(get_offscreen_context());
	}

	void
	OpenGL_fin ()
	{
	}

	void
	OpenGL_set_context (Context context)
	{
		EAGLContext* c = (EAGLContext*) ((OpenGLContext*) &context)->ptr1;
		[EAGLContext setCurrentContext: c];
	}

	Context
	OpenGL_get_context ()
	{
		return Context([EAGLContext currentContext]);
	}


	Context
	get_offscreen_context ()
	{
		static OpenGLContext context;
		if (!context)
			context.ptr1 = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES3];
		return context;
	}


}// Rays
