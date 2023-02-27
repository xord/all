// -*- c++ -*-
#pragma once
#ifndef __RAYS_COORD_H__
#define __RAYS_COORD_H__


#include <rays/defs.h>


namespace Rays
{


	struct Coord2
	{

		typedef Coord2 This;

		enum {SIZE = 2};

		union
		{
			struct {coord x, y;};
			struct {coord s, t;};
			coord array[SIZE];
		};

		Coord2& reset (coord value = 0);

		Coord2& reset (coord x, coord y);

		size_t size () const;

		String inspect () const;

		      coord& operator [] (size_t index);

		const coord& operator [] (size_t index) const;

	};// Coord2


	struct Coord3
	{

		typedef Coord3 This;

		enum {SIZE = 3};

		union
		{
			struct {coord x,   y,     z;};
			struct {coord s,   t,     p;};
			struct {coord r,   g,     b;};
			struct {coord red, green, blue;};
			coord array[SIZE];
		};

		This& operator = (const Coord2& rhs);

		Coord3& reset (coord value = 0);

		Coord3& reset (coord x, coord y, coord z = 0);

		size_t size () const;

		String inspect () const;

		      coord& operator [] (size_t index);

		const coord& operator [] (size_t index) const;

	};// Coord3


	struct Coord4
	{

		typedef Coord4 This;

		enum {SIZE = 4};

		union
		{
			struct {coord x,   y,     z,    w;};
			struct {coord s,   t,     p,    q;};
			struct {coord r,   g,     b,    a;};
			struct {coord red, green, blue, alpha;};
			coord array[SIZE];
		};

		This& operator = (const Coord2& rhs);

		This& operator = (const Coord3& rhs);

		Coord4& reset (coord value = 0);

		Coord4& reset (coord x, coord y, coord z = 0, coord w = 1);

		size_t size () const;

		String inspect () const;

		      coord& operator [] (size_t index);

		const coord& operator [] (size_t index) const;

	};// Coord4


}// Rays


#endif//EOH
