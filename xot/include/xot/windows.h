// -*- c++ -*-
#pragma once
#ifndef __XOT_WINDOWS_H__
#define __XOT_WINDOWS_H__


#ifdef WIN32
	#undef  _WIN32_WINNT
	#ifdef XOT_WIN32_WINNT
		#define _WIN32_WINNT XOT_WIN32_WINNT
	#else
		#define _WIN32_WINNT _WIN32_WINNT_WIN7
	#endif
	#include <windows.h>
	#include <windowsx.h>
#endif


#endif//EOH
