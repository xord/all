// -*- objc -*-
#include "helper.h"


namespace Rays
{


	void
	safe_cfrelease (CFTypeRef ref)
	{
		if (ref) CFRelease(ref);
	}


	CFStringPtr
	cfstring (const char* str)
	{
		CFStringRef ref = CFStringCreateWithCString(
			kCFAllocatorDefault, str, kCFStringEncodingUTF8);
		return CFStringPtr(ref, safe_cfrelease);
	}


}// Rays
