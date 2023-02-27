// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WIN32_DEFS_H__
#define __REFLEX_SRC_WIN32_DEFS_H__


#include <windows.h>
#include <reflex/defs.h>


namespace Reflex
{


	struct Win32Key : public Key
	{

		Win32Key (UINT msg, WPARAM wp, LPARAM lp);

	};// Win32Key


	struct Win32Points : public Points
	{

		Win32Points (UINT msg, WPARAM wp, LPARAM lp);

	};// Win32Points


}// Reflex


#endif//EOH
