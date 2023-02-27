// -*- c++ -*-
#pragma once
#ifndef __RAYS_BOUNDS_H__
#define __RAYS_BOUNDS_H__


#include <rays/defs.h>
#include <rays/point.h>


namespace Rays
{


	struct Bounds
	{

		typedef Bounds This;

		union
		{
			struct
			{
				coord x, y, z;
				union
				{
					struct {coord width, height, depth;};
					struct {coord w,     h,      d;};
				};
			};
			coord array[6];
		};

		Bounds (coord size = 0);

		Bounds (                           coord width, coord height, coord depth = 0);

		Bounds (coord x, coord y,          coord width, coord height);

		Bounds (coord x, coord y, coord z, coord width, coord height, coord depth);

		Bounds (const Point& size);

		Bounds (const Point& position, const Point& size);

		Bounds dup () const;

		bool is_intersect (const Bounds& other, int dimension = 2) const;

		bool is_include (coord x, coord y, coord z = 0, int dimension = 2) const;

		bool is_include (const Point& p, int dimension = 2) const;

		Bounds& reset (coord size = 0);

		Bounds& reset (                           coord width, coord height, coord depth = 0);

		Bounds& reset (coord x, coord y,          coord width, coord height);

		Bounds& reset (coord x, coord y, coord z, coord width, coord height, coord depth);

		Bounds& reset (const Point& size);

		Bounds& reset (const Point& position, const Point& size);

		Bounds& move_to (coord x, coord y, coord z = 0);

		Bounds& move_to (const Point& point);

		Bounds& move_by (coord x, coord y, coord z = 0);

		Bounds& move_by (const Point& point);

		Bounds& resize_to (coord x, coord y, coord z = 0);

		Bounds& resize_to (const Point& point);

		Bounds& resize_by (coord x, coord y, coord z = 0);

		Bounds& resize_by (const Point& point);

		Bounds& inset_by (coord x, coord y, coord z = 0);

		Bounds& inset_by (const Point& point);

		void set_left (coord left);

		coord    left () const;

		void set_right (coord right);

		coord    right () const;

		void set_top (coord top);

		coord    top () const;

		void set_bottom (coord bottom);

		coord    bottom () const;

		void set_back (coord back);

		coord    back () const;

		void set_front (coord front);

		coord    front () const;

		void set_position (coord x, coord y, coord z = 0);

		void set_position (const Point& position);

		      Point& position ();

		const Point& position () const;

		void set_size (coord width, coord height, coord depth = 0);

		void set_size (const Point& size);

		      Point& size ();

		const Point& size () const;

		void set_center (coord x, coord y, coord z = 0);

		void set_center (const Point& center);

		Point    center () const;

		String inspect () const;

		      Point& operator [] (size_t index);

		const Point& operator [] (size_t index) const;

		operator bool () const;

		bool operator ! () const;

		Bounds& operator &= (const Bounds& rhs);

		Bounds& operator |= (const Bounds& rhs);

		Bounds& operator |= (const Point& rhs);

		friend bool operator == (const Bounds& lhs, const Bounds& rhs);

		friend bool operator != (const Bounds& lhs, const Bounds& rhs);

		friend Bounds operator & (const Bounds& lhs, const Bounds& rhs);

		friend Bounds operator | (const Bounds& lhs, const Bounds& rhs);

		friend Bounds operator | (const Bounds& lhs, const Point&  rhs);

		friend Bounds operator | (const Point&  lhs, const Bounds& rhs);

	};// Bounds


	Bounds invalid_bounds ();


}// Rays


#endif//EOH
