// -*- c++ -*-
#pragma once
#ifndef __RAYS_POLYLINE_H__
#define __RAYS_POLYLINE_H__


#include <vector>
#include <xot/pimpl.h>
#include <rays/defs.h>
#include <rays/point.h>
#include <rays/bounds.h>


namespace Rays
{


	struct Color;
	class Polygon;


	class Polyline
	{

		public:

			typedef std::vector<Point> PointList;

			typedef PointList::const_iterator const_iterator;

			Polyline ();

			Polyline (
				const Point* points, size_t size, bool loop = false,
				const Color* colors = NULL, const Coord3* texcoords = NULL,
				bool hole = false);

			Polyline (
				const Point* points, size_t size, bool loop, bool fill,
				const Color* colors = NULL, const Coord3* texcoords = NULL,
				bool hole = false);

			~Polyline ();

			bool expand (
				Polygon* result,
				coord width,
				CapType cap       = CAP_DEFAULT,
				JoinType join     = JOIN_DEFAULT,
				coord miter_limit = JOIN_DEFAULT_MITER_LIMIT) const;

			Bounds bounds () const;

			bool loop () const;

			bool fill () const;

			bool hole () const;

			const Point* points () const;

			const Color* colors () const;

			const Coord3* texcoords () const;

			size_t size () const;

			bool empty () const;

			const_iterator begin () const;

			const_iterator end () const;

			const Point& operator [] (size_t index) const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Polyline


}// Rays


#endif//EOH
