// -*- c++ -*-
#pragma once
#ifndef __RAYS_RAYS_H__
#define __RAYS_RAYS_H__


#include <rays/defs.h>


namespace Rays
{


	typedef void* Context;


	void init ();

	void fin ();


	Context get_offscreen_context ();

	void activate_offscreen_context ();

	String get_renderer_info ();


}// Rays


#endif//EOH
