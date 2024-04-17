// -*- objc -*-
#include "../opengl.h"


#import <OpenGLES/EAGL.h>
#include <rays/exception.h>


namespace Rays
{


	class OpenGLContext : public Context
	{

		typedef OpenGLContext This;

		public:

			typedef Xot::Ref<This> Ref;

			OpenGLContext (EAGLContext* context)
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
				[EAGLContext setCurrentContext: context];
			}

			operator bool () const override
			{
				return context;
			}

		private:

			EAGLContext* context;

	};// OpenGLContext


	namespace global
	{

		OpenGLContext::Ref current_context;

		OpenGLContext::Ref offscreen_context;

	}// global


	static EAGLContext*
	create_offscreen_context ()
	{
		return [[[EAGLContext alloc]
			initWithAPI: kEAGLRenderingAPIOpenGLES3]
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
			[EAGLContext setCurrentContext: nil];
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
