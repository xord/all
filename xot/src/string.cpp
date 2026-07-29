#include "xot/string.h"


#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <algorithm>
#include "xot/exception.h"

#if defined(OSX) || defined(IOS)
	#import <CoreFoundation/CoreFoundation.h>
#elif defined(WIN32)
	#include "xot/windows.h"
#endif


namespace Xot
{


	String::String ()
	{
	}

	String::String (const char* str)
	:	Super(str)
	{
	}

	String::String (const char* str, size_t size)
	:	Super(str, size)
	{
	}

	String::String (const std::string& str)
	:	Super(str)
	{
	}

	String
	String::upcase () const
	{
		String s = c_str();
		std::transform(
			s.begin(), s.end(), s.begin(),
			[](int c) {return toupper(c);});
		return s;
	}

	String
	String::downcase () const
	{
		String s = c_str();
		std::transform(
			s.begin(), s.end(), s.begin(),
			[](int c) {return tolower(c);});
		return s;
	}

	String
	String::strip () const
	{
		String s = c_str();
		auto isspace = [](int c) {return std::isspace(c);};
		auto head = std::find_if_not(s.begin(), s.end(), isspace);
		auto tail = std::find_if(    head,      s.end(), isspace);
		return String(head, tail);
	}

	String::operator const char* () const
	{
		return c_str();
	}

	String
	operator + (const String& lhs, const String& rhs)
	{
		String t = lhs;
		t += rhs;
		return t;
	}

	String
	operator + (const String& lhs, const char* rhs)
	{
		String t = lhs;
		t += rhs;
		return t;
	}

	String
	operator + (const char* lhs, const String& rhs)
	{
		String t = lhs;
		t += rhs;
		return t;
	}

#if defined(OSX) || defined(IOS)

	static void
	release_cfstring (CFTypeRef ref)
	{
		if (ref) CFRelease(ref);
	}

	CFStringPtr
	String::to_cfstr () const
	{
		return CFStringPtr(
			CFStringCreateWithCString(kCFAllocatorDefault, c_str(), kCFStringEncodingUTF8),
			release_cfstring);
	}

#elif defined(WIN32)

	String::String (const wchar_t* str, size_t size)
	{
		if (size > INT_MAX)
			argument_error(__FILE__, __LINE__);
		if (!str || size == 0) return;

		int len = WideCharToMultiByte(CP_UTF8, 0, str, (int) size, NULL, 0, NULL, NULL);
		if (len <= 0) system_error(__FILE__, __LINE__);

		resize((size_t) len);
		WideCharToMultiByte(CP_UTF8, 0, str, (int) size, &(*this)[0], len, NULL, NULL);
	}

	std::wstring
	String::to_wstr () const
	{
		if (empty()) return std::wstring();

		size_t size = this->size();
		if (size > INT_MAX)
			invalid_state_error(__FILE__, __LINE__);

		int len = MultiByteToWideChar(CP_UTF8, 0, data(), (int) size, NULL, 0);
		if (len <= 0) system_error(__FILE__, __LINE__);

		std::wstring result;
		result.resize((size_t) len);
		MultiByteToWideChar(CP_UTF8, 0, data(), (int) size, &result[0], len);
		return result;
	}

#endif


	String
	stringf (const char* format, ...)
	{
		va_list args;
		va_start(args, format);
		String ret = stringf(format, args);
		va_end(args);
		return ret;
	}

	String
	stringf (const char* format, va_list args)
	{
		enum {BUFSIZE = 256};
		char stack[BUFSIZE];
		if (vsnprintf(&stack[0], BUFSIZE, format, args) <= BUFSIZE)
			return &stack[0];

		int bufsize = BUFSIZE;// vscprintf(format, args);
		std::unique_ptr<char[]> heap;
		while (true)
		{
			bufsize *= 2;
			heap.reset(new char[bufsize]);
			if (vsnprintf(&heap[0], bufsize, format, args) <= bufsize)
				return &heap[0];
		}

		return NULL;
	}

	void
	split (StringList* result, const char* string, char separator)
	{
		if (separator == '\0')
			argument_error(__FILE__, __LINE__);

		result->clear();
		for (const char* p = string;;)
		{
			const char* psep = strchr(p, separator);
			if (psep)
			{
				result->emplace_back(p, psep);
				p = psep + 1;
			}
			else
			{
				result->emplace_back(p);
				break;
			}
		}
	}

	template <> String
	to_s<int> (const int& val)
	{
		return stringf("%d", val);
	}

	template <> String
	to_s<float> (const float& val)
	{
		return stringf("%f", val);
	}

	template <> String
	to_s<double> (const double& val)
	{
		return stringf("%f", val);
	}

	typedef const char* const_char_p;

	template <> String
	to_s<const_char_p> (const const_char_p& val)
	{
		return val;
	}

	template <> String
	to_s<String> (const String& val)
	{
		return val;
	}

#if defined(OSX) || defined(IOS)

	template <> String
	to_s<CFStringRef> (const CFStringRef& val)
	{
		if (!val || CFGetTypeID(val) != CFStringGetTypeID())
			return String();

		CFIndex len = CFStringGetMaximumSizeForEncoding(
			CFStringGetLength(val), kCFStringEncodingUTF8) + 1;

		std::unique_ptr<char[]> buffer(new char[len]);
		if (!CFStringGetCString(val, buffer.get(), len, kCFStringEncodingUTF8))
			system_error(__FILE__, __LINE__);

		return buffer.get();
	}

	template <> String
	to_s<CFStringPtr> (const CFStringPtr& val)
	{
		return to_s((CFStringRef) val.get());
	}

#endif


}// Xot
