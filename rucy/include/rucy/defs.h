// -*- c++ -*-
#pragma once
#ifndef __RUCY_DEFS_H__
#define __RUCY_DEFS_H__


#if defined(WIN32) && defined(GCC) && defined(RUCY)
	#define RUCY_EXPORT __declspec(dllexport)
#else
	#define RUCY_EXPORT
#endif


#endif//EOH
