#include "xot/exception.h"


#include "xot/windows.h"


namespace Xot
{


	XotError::XotError (const char* str)
	:	Super(str ? str : "")
	{
	}


	InvalidStateError::InvalidStateError (const char* str)
	:	Super(str)
	{
	}


	SystemError::SystemError (const char* str)
	:	Super(str)
	{
	}


	NotImplementedError::NotImplementedError (const char* str)
	:	Super(str)
	{
	}


	String
	error_text (const char* file, int line, const char* str)
	{
		String s = str;
		if (file) s = stringf("%s:%d: ", file, line) + s;
		return s;
	}

	String
	system_error_text (const char* file, int line, const char* str)
	{
		String s = str;

		#ifdef WIN32
			DWORD lasterror = GetLastError();
			if (lasterror != 0)
			{
				LPVOID msg = NULL;
				DWORD flags =
					FORMAT_MESSAGE_ALLOCATE_BUFFER |
					FORMAT_MESSAGE_FROM_SYSTEM |
					FORMAT_MESSAGE_IGNORE_INSERTS;
				if (FormatMessageA(
					flags, NULL, lasterror, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
					(LPSTR) &msg, 0, NULL))
				{
					String m = (LPCSTR) msg;
					if (!m.empty()) s += ": " + m;
				}
				LocalFree(msg);
			}
		#endif

		return error_text(file, line, s);
	}


	namespace ErrorFunctions
	{

		void
		xot_error (const char* file, int line, const char* format, ...)
		{
			XOT_STRINGF(format, s);
			throw XotError(error_text(file, line, s));
		}

		void
		argument_error (const char* file, int line, const char* format, ...)
		{
			XOT_STRINGF(format, s);
			throw std::invalid_argument(error_text(file, line, s));
		}

		void
		index_error (const char* file, int line, const char* format, ...)
		{
			XOT_STRINGF(format, s);
			throw std::out_of_range(error_text(file, line, s));
		}

		void
		range_error (const char* file, int line, const char* format, ...)
		{
			XOT_STRINGF(format, s);
			throw std::range_error(error_text(file, line, s));
		}

		void
		invalid_state_error (const char* file, int line, const char* format, ...)
		{
			XOT_STRINGF(format, s);
			throw InvalidStateError(error_text(file, line, s));
		}

		void
		system_error (const char* file, int line, const char* format, ...)
		{
			XOT_STRINGF(format, s);
			throw SystemError(system_error_text(file, line, s));
		}

		void
		not_implemented_error (const char* file, int line, const char* format, ...)
		{
			XOT_STRINGF(format, s);
			throw NotImplementedError(error_text(file, line, s));
		}

	}// ErrorFunctions


}// Xot
