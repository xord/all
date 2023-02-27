// -*- c++ -*-
#pragma once
#ifndef __XOT_DEFS_H__
#define __XOT_DEFS_H__


#include <stddef.h>


#ifdef CYGWIN

	typedef unsigned short ushort;

	typedef unsigned int   uint;

	typedef unsigned long  ulong;

#endif


namespace Xot
{


	namespace Types
	{


		typedef   signed char schar;

		typedef unsigned char uchar;

		#ifdef CYGWIN

			using ::ushort;
			using ::uint;
			using ::ulong;

		#else

			typedef unsigned short ushort;

			typedef unsigned int   uint;

			typedef unsigned long  ulong;

		#endif

		typedef          long long  longlong;

		typedef unsigned long long ulonglong;


	}// Types


	using namespace Types;


}// Xot


#endif//EOH
