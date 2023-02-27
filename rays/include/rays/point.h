// -*- c++ -*-
#pragma once
#ifndef __RAYS_POINT_H__
#define __RAYS_POINT_H__


#include <rays/coord.h>


namespace Rays
{


	struct Point : public Coord3
	{

		typedef Point This;

		typedef Coord3 Super;

		Point (coord value = 0);

		Point (coord x, coord y, coord z = 0);

		This dup () const;

		This& reset (coord value = 0);

		This& reset (coord x, coord y, coord z = 0);

		This& move_to (coord x, coord y, coord z = 0);

		This& move_to (const This& point);

		This& move_by (coord x, coord y, coord z = 0);

		This& move_by (const This& point);

		void rotate (float degree);

		coord length () const;

		This normal () const;

		void normalize ();

		This operator - () const;

		This& operator += (coord       rhs);

		This& operator += (const This& rhs);

		This& operator -= (coord       rhs);

		This& operator -= (const This& rhs);

		This& operator *= (coord       rhs);

		This& operator *= (const This& rhs);

		This& operator /= (coord       rhs);

		This& operator /= (const This& rhs);

		friend bool operator == (const This& lhs, const This& rhs);

		friend bool operator != (const This& lhs, const This& rhs);

		friend This operator + (coord       lhs, const This& rhs);

		friend This operator + (const This& lhs, coord       rhs);

		friend This operator + (const This& lhs, const This& rhs);

		friend This operator - (coord       lhs, const This& rhs);

		friend This operator - (const This& lhs, coord       rhs);

		friend This operator - (const This& lhs, const This& rhs);

		friend This operator * (coord       lhs, const This& rhs);

		friend This operator * (const This& lhs, coord       rhs);

		friend This operator * (const This& lhs, const This& rhs);

		friend This operator / (coord       lhs, const This& rhs);

		friend This operator / (const This& lhs, coord       rhs);

		friend This operator / (const This& lhs, const This& rhs);

	};// Point


	coord dot (const Point& p1, const Point& p2);

	Point cross (const Point& p1, const Point& p2);


}// Rays


#endif//EOH
