// -*- objc -*-
#include "rucy/exception.h"


#import <Foundation/Foundation.h>


namespace Rucy
{


	Xot::String
	get_native_unknown_exception_message (std::exception_ptr exception)
	{
		try
		{
			std::rethrow_exception(exception);
		}
		catch (NSException* e)
		{
			return Xot::stringf(
				"%s: %s", e.name.UTF8String, e.reason ? e.reason.UTF8String : "");
		}
		catch (...)
		{
			return "";
		}
	}


}// Rucy
