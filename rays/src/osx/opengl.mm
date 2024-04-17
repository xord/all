// -*- objc -*-
#include "../opengl.h"


#import <AppKit/AppKit.h>
#include <rays/exception.h>


namespace Rays
{


	class OpenGLContext : public Context
	{

		typedef OpenGLContext This;

		public:

			typedef Xot::Ref<This> Ref;

			OpenGLContext (NSOpenGLContext* context)
			:	context(context)
			{
				[context retain];
			}

			~OpenGLContext () override
			{
				[context release];
			}

			void activate ()
			{
				[context makeCurrentContext];
			}

			operator bool () const override
			{
				return context;
			}

		private:

			NSOpenGLContext* context;

	};// OpenGLContext


	namespace global
	{

		OpenGLContext::Ref current_context;

		OpenGLContext::Ref offscreen_context;

	}// global


	static NSOpenGLContext*
	create_offscreen_context ()
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
		return [[[NSOpenGLContext alloc]
			initWithFormat: pf shareContext: nil]
			autorelease];
	}

	void
	OpenGL_init ()
	{
		if (global::offscreen_context)
			rays_error(__FILE__, __LINE__, "already initialized.");

		global::offscreen_context = new OpenGLContext(create_offscreen_context());
		OpenGL_set_context(get_offscreen_context());
	}

	void
	OpenGL_fin ()
	{
		if (!global::offscreen_context)
			rays_error(__FILE__, __LINE__, "not initialized.");

		global::current_context.reset();
		global::offscreen_context.reset();
	}

	void
	OpenGL_set_context (Context* context)
	{
		global::current_context = (OpenGLContext*) context;
		if (global::current_context)
			global::current_context->activate();
		else
			[NSOpenGLContext clearCurrentContext];
	}

	Context*
	OpenGL_get_context ()
	{
		return global::current_context.get();
	}


	Context*
	get_offscreen_context ()
	{
		return global::offscreen_context.get();
	}


}// Rays
