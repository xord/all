#include "rays/ruby/exception.h"


#include "defs.h"


static Class cRaysError;
static Class cOpenGLError;
static Class cShaderError;

void
Init_rays_exception ()
{
	Module mRays = define_module("Rays");

	cRaysError   = mRays.define_class("RaysError", rb_eRuntimeError);
	cOpenGLError = mRays.define_class("OpenGLError", cRaysError);
	cShaderError = mRays.define_class("ShaderError", cOpenGLError);
}


namespace Rays
{


	Class
	rays_error_class ()
	{
		return cRaysError;
	}

	Class
	opengl_error_class ()
	{
		return cOpenGLError;
	}

	Class
	shader_error_class ()
	{
		return cShaderError;
	}


}// Rays
