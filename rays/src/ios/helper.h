// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_IOS_HELPER_H__
#define __RAYS_SRC_IOS_HELPER_H__


#include <memory>
#include <CoreFoundation/CoreFoundation.h>


namespace Rays
{


	void safe_cfrelease (CFTypeRef ref);


	typedef std::shared_ptr<const __CFString> CFStringPtr;

	CFStringPtr cfstring (const char* str);


}// Rays


#endif//EOH
