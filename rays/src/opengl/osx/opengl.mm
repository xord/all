// -*- objc -*-
#include "../../renderer.h"


#import <AppKit/AppKit.h>
#include "rays/rays.h"
#include "rays/exception.h"


namespace Rays
{


	static NSOpenGLContext*
	get_opengl_offscreen_context ()
	{
		static NSOpenGLContext* context = nil;
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
			context = [[NSOpenGLContext alloc] initWithFormat: pf shareContext: nil];
		}
		return context;
	}


	void
	Renderer_init ()
	{
		activate_offscreen_context();
	}

	void
	Renderer_fin ()
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
		[get_opengl_offscreen_context() makeCurrentContext];
	}


}// Rays
