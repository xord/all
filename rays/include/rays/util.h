// -*- c++ -*-
#pragma once
#ifndef __RAYS_UTIL_H__
#define __RAYS_UTIL_H__


#include <rays/defs.h>


namespace Rays
{


	struct Coord3;


	coord perlin (coord x);

	coord perlin (coord x, coord y);

	coord perlin (coord x, coord y, coord z);

	coord perlin (coord x, coord y, coord z, coord w);

	coord perlin (const Coord3& position);


	coord simplex (coord x);

	coord simplex (coord x, coord y);

	coord simplex (coord x, coord y, coord z);

	coord simplex (coord x, coord y, coord z, coord w);

	coord simplex (const Coord3& position);


}// Rays


#endif//EOH
