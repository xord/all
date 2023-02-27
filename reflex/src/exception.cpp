#include "reflex/exception.h"


namespace Reflex
{


	ReflexError::ReflexError (const char* str)
	:	Super(str)
	{
	}


	LayoutError::LayoutError (const char* str)
	:	Super(str)
	{
	}


	PhysicsError::PhysicsError (const char* str)
	:	Super(str)
	{
	}


	namespace ErrorFunctions
	{

		void
		reflex_error (const char* file, int line, const char* format, ...)
		{
			XOT_STRINGF(format, s);
			throw ReflexError(Xot::error_text(file, line, s));
		}

		void
		layout_error (const char* file, int line, const char* format, ...)
		{
			XOT_STRINGF(format, s);
			throw LayoutError(Xot::error_text(file, line, s));
		}

		void
		physics_error (const char* file, int line, const char* format, ...)
		{
			XOT_STRINGF(format, s);
			throw PhysicsError(Xot::error_text(file, line, s));
		}

	}// ErrorFunctions


}// Reflex
