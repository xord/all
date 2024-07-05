// -*- c++ -*-
#pragma once
#ifndef __XOT_WINDOWS_H__
#define __XOT_WINDOWS_H__


#ifdef WIN32
	#undef  _WIN32_WINNT
	#define _WIN32_WINNT _WIN32_WINNT_WIN7
	#include <windows.h>
	#include <windowsx.h>
#endif


#endif//EOH
