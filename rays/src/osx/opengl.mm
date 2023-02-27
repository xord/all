// -*- objc -*-
#include "../opengl.h"


#import <AppKit/AppKit.h>


namespace Rays
{


	void
	OpenGL_set_context (Context context)
	{
		NSOpenGLContext* c = (NSOpenGLContext*) context;
		[c makeCurrentContext];
	}

	Context
	OpenGL_get_context ()
	{
		return [NSOpenGLContext currentContext];
	}


	Context
	get_offscreen_context ()
	{
		static Context context = NULL;
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
			context = [[[NSOpenGLContext alloc]
				initWithFormat: pf shareContext: nil] autorelease];
		}
		return context;
	}


}// Rays
