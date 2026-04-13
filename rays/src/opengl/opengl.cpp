#include "opengl.h"


#include "rays/exception.h"


namespace Rays
{


	bool
	OpenGL_has_error ()
	{
		return glGetError() != GL_NO_ERROR;
	}

	static String
	get_error_name (GLenum error)
	{
		switch (error)
		{
			case GL_NO_ERROR:          return "GL_NO_ERROR";
			case GL_INVALID_ENUM:      return "GL_INVALID_ENUM";
			case GL_INVALID_VALUE:     return "GL_INVALID_VALUE";
			case GL_INVALID_OPERATION: return "GL_INVALID_OPERATION";
			case GL_OUT_OF_MEMORY:     return "GL_OUT_OF_MEMORY";
			#if !defined(GL_VERSION_3_0) && !defined(GL_ES_VERSION_2_0)
				case GL_STACK_OVERFLOW:  return "GL_STACK_OVERFLOW";
				case GL_STACK_UNDERFLOW: return "GL_STACK_UNDERFLOW";
				case GL_INVALID_FRAMEBUFFER_OPERATION: return "GL_INVALID_FRAMEBUFFER_OPERATION";
				case GL_TABLE_TOO_LARGE: return "GL_TABLE_TOO_LARGE";
			#endif
			default:                   return "UNKNOWN ERROR";
		}
	}

	void
	OpenGL_check_error (const char* file, int line)
	{
		GLenum e = glGetError();
		if (e != GL_NO_ERROR)
			opengl_error(file, line, "OpenGL error %s", get_error_name(e).c_str());
	}

	void
	OpenGL_check_error (const char* file, int line, const char* format, ...)
	{
		GLenum e = glGetError();
		if (e != GL_NO_ERROR)
		{
			XOT_STRINGF(format, s);
			opengl_error(
				file, line,
				"OpenGL error %s: %s", get_error_name(e).c_str(), s.c_str());
		}
	}


	String
	get_renderer_info ()
	{
		return Xot::stringf(
			"{\"OpenGL Version\":\"%s\",\"GLSL Version\":\"%s\",\"Renderer\":\"%s\",\"Vendor\":\"%s\"}",
			glGetString(GL_VERSION),
			glGetString(GL_SHADING_LANGUAGE_VERSION),
			glGetString(GL_RENDERER),
			glGetString(GL_VENDOR));
	}


}// Rays
