// -*- c++ -*-
#pragma once
#ifndef __RAYS_MATRIX_H__
#define __RAYS_MATRIX_H__


#include <rays/defs.h>
#include <rays/point.h>


namespace Rays
{


	struct Matrix
	{

		typedef Matrix This;

		enum {NROW = 4, NCOLUMN = 4, NELEM = NROW * NCOLUMN};

		union
		{
			struct
			{
				coord
					x0, y0, z0, w0,
					x1, y1, z1, w1,
					x2, y2, z2, w2,
					x3, y3, z3, w3;
			};
			Coord4 column[NCOLUMN];
			coord array[NELEM];
		};

		Matrix (coord value = 1);

		Matrix (
			coord x0, coord x1, coord x2, coord x3,
			coord y0, coord y1, coord y2, coord y3,
			coord z0, coord z1, coord z2, coord z3,
			coord w0, coord w1, coord w2, coord w3);

		Matrix (const coord* elements, size_t size);

		This dup () const;

		This& reset (coord value = 1);

		This& reset (
			coord x0, coord x1, coord x2, coord x3,
			coord y0, coord y1, coord y2, coord y3,
			coord z0, coord z1, coord z2, coord z3,
			coord w0, coord w1, coord w2, coord w3);

		This& reset (const coord* elements, size_t size);

		This& translate (coord x, coord y, coord z = 0);

		This& translate (const Coord3& translate);

		This& scale (coord x, coord y, coord z = 1);

		This& scale (const Coord3& scale);

		This& rotate (float degree, coord x = 0, coord y = 0, coord z = 1);

		This& rotate (float degree, const Coord3& normalized_axis);

		coord& at (int row, int column);

		coord  at (int row, int column) const;

		String inspect () const;

		coord& operator [] (int index);

		coord  operator [] (int index) const;

		This& operator *= (const This&  rhs);

		Point operator *  (const Point& rhs) const;

		This  operator *  (const This&  rhs) const;

	};// Matrix


}// Rays


#endif//EOH
