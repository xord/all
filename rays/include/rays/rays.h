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


}// Rays


#endif//EOH
