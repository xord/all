// -*- objc -*-
#include "helper.h"


namespace Rays
{


	void
	safe_cfrelease (CFTypeRef ref)
	{
		if (ref) CFRelease(ref);
	}


	CFString
	cfstring (const char* str)
	{
		CFStringRef ref = CFStringCreateWithCString(
			kCFAllocatorDefault, str, kCFStringEncodingUTF8);
		return CFString(ref, safe_cfrelease);
	}


}// Rays
