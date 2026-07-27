// -*- c++ -*-
#pragma once
#ifndef __REFLEX_TERMINAL_DEFS_H__
#define __REFLEX_TERMINAL_DEFS_H__


#include <reflex/defs.h>


#if defined(WIN32) && defined(GCC) && defined(REFLEX_TERMINAL)
	#define REFLEX_TERMINAL_EXPORT __declspec(dllexport)
#else
	#define REFLEX_TERMINAL_EXPORT
#endif


#endif//EOH
