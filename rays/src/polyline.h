// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_POLYLINE_H__
#define __RAYS_SRC_POLYLINE_H__


#include <float.h>
#include <clipper.hpp>
#include "rays/polyline.h"
#include "rays/exception.h"


namespace Rays
{


	static const double CLIPPER_SCALE = 1000;


	inline ClipperLib::cInt
	to_clipper (coord value)
	{
		return (ClipperLib::cInt) (value * CLIPPER_SCALE);
	}

	inline coord
	from_clipper (ClipperLib::cInt value)
	{
		double v = value / CLIPPER_SCALE;
		if (v <= -FLT_MAX || FLT_MAX <= v)
			argument_error(__FILE__, __LINE__);

		return (coord) v;
	}

	inline ClipperLib::IntPoint
	to_clipper (const Point& point)
	{
		return ClipperLib::IntPoint(
			to_clipper(point.x),
			to_clipper(point.y));
	}

	inline Point
	from_clipper (const ClipperLib::IntPoint& point)
	{
		return Point(
			from_clipper(point.X),
			from_clipper(point.Y));
	}


	void Polyline_create (
		Polyline* polyline, const ClipperLib::Path& path, bool loop,
		bool hole = false);

	void Polyline_get_path (
		ClipperLib::Path* path, const Polyline& polyline,
		bool hole = false);

	bool Polyline_expand (
		Polygon* result, const Polyline& polyline,
		coord width, CapType cap, JoinType join, coord miter_limit);


}// Rays


#endif//EOH
