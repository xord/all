#include "rays/exception.h"


#include <xot/string.h>


namespace Rays
{


	RaysError::RaysError (const char* str)
	:	Super(str)
	{
	}


	OpenGLError::OpenGLError (const char* str)
	:	Super(str)
	{
	}


	ShaderError::ShaderError (const char* str)
	:	Super(str)
	{
	}


	namespace ErrorFunctions
	{

		void
		rays_error (const char* file, int line, const char* format, ...)
		{
			XOT_STRINGF(format, s);
			throw RaysError(Xot::error_text(file, line, s));
		}

		void
		opengl_error (const char* file, int line, const char* format, ...)
		{
			XOT_STRINGF(format, s);
			throw OpenGLError(Xot::error_text(file, line, s));
		}

		void
		shader_error (const char* file, int line, const char* format, ...)
		{
			XOT_STRINGF(format, s);
			throw ShaderError(Xot::error_text(file, line, s));
		}

	}// ErrorFunctions


}// Rays
