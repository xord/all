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
		activate_offscreen_context();
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

	void
	activate_offscreen_context ()
	{
		[EAGLContext setCurrentContext: get_opengl_offscreen_context()];
	}

	String
	get_renderer_info ()
	{
		return Xot::stringf(
			"OpenGL (Version: %s, Renderer: %s, Vendor: %s)",
			glGetString(GL_VERSION),
			glGetString(GL_RENDERER),
			glGetString(GL_VENDOR));
	}


}// Rays
