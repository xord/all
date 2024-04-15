// -*- objc -*-
#include "../opengl.h"


#import <AppKit/AppKit.h>


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
		NSOpenGLContext* c = (NSOpenGLContext*) ((OpenGLContext*) &context)->ptr1;
		[c makeCurrentContext];
	}

	Context
	OpenGL_get_context ()
	{
		return Context([NSOpenGLContext currentContext]);
	}


	Context
	get_offscreen_context ()
	{
		static OpenGLContext context;
		if (!context)
		{
			NSOpenGLPixelFormatAttribute attribs[] =
			{
				//NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
				//NSOpenGLPFAAccelerated, NSOpenGLPFANoRecovery,
				//NSOpenGLPFADoubleBuffer,
				NSOpenGLPFAAllowOfflineRenderers,
				NSOpenGLPFAColorSize, 32,
				NSOpenGLPFADepthSize, 32,
				//NSOpenGLPFAMultisample,
				//NSOpenGLPFASampleBuffers, 1,
				//NSOpenGLPFASamples, 4,
				0
			};
			NSOpenGLPixelFormat* pf = [[[NSOpenGLPixelFormat alloc]
				initWithAttributes: attribs] autorelease];
			context.ptr1 = [[[NSOpenGLContext alloc]
				initWithFormat: pf shareContext: nil] autorelease];
		}
		return context;
	}


}// Rays
