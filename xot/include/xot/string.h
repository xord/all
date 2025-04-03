// -*- c++ -*-
#pragma once
#ifndef __XOT_STRING_H__
#define __XOT_STRING_H__


#include <stdarg.h>
#include <memory>
#include <string>
#include <vector>


#define XOT_STRINGF(format, result) \
	Xot::String result; \
	do \
	{ \
		if (format) \
		{ \
			va_list args; \
			va_start(args, format); \
			result = Xot::stringf(format, args); \
			va_end(args); \
		} \
	} \
	while (false)


#ifdef OSX
	struct __CFString;
#endif


namespace Xot
{


	class String : public std::string
	{

		typedef std::string Super;

		public:

			String ();

			String (const char* str);

			template <typename ITERATOR>
			String (ITERATOR begin, ITERATOR end) : Super(begin, end) {}

			String upcase () const;

			String downcase () const;

			String strip () const;

			operator const char* () const;

			friend String operator + (const String& lhs, const String& rhs);

			friend String operator + (const String& lhs, const char*   rhs);

			friend String operator + (const char*   lhs, const String& rhs);

	};// String


	typedef std::vector<String> StringList;


	String stringf (const char* format, ...);

	String stringf (const char* format, va_list args);

	void split(StringList* result, const char* string, char separator = '\n');

	template <typename T> String to_s (const T& val);


#ifdef OSX

	typedef std::shared_ptr<const __CFString> CFStringPtr;

	CFStringPtr cfstring (const char* str);

#endif


}// Xot


#endif//EOH
