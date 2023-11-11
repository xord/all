// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_POLYLINE_H__
#define __RAYS_SRC_POLYLINE_H__


#include <float.h>
#include <clipper2/clipper.h>
#include "rays/polyline.h"
#include "rays/exception.h"


namespace Rays
{


	typedef int64_t                 ClipperCoord;
	typedef Clipper2Lib::Point64    ClipperPoint;
	typedef Clipper2Lib::Path64     ClipperPath;
	typedef Clipper2Lib::Paths64    ClipperPaths;
	typedef Clipper2Lib::PolyTree64 ClipperPolyTree;
	typedef Clipper2Lib::Clipper64  Clipper;

	static const double CLIPPER_SCALE = 1000;


	inline ClipperCoord
	to_clipper (coord value)
	{
		return (ClipperCoord) (value * CLIPPER_SCALE);
	}

	inline coord
	from_clipper (ClipperCoord value)
	{
		double v = value / CLIPPER_SCALE;
		if (v <= -FLT_MAX || FLT_MAX <= v)
			argument_error(__FILE__, __LINE__);

		return (coord) v;
	}

	inline ClipperPoint
	to_clipper (const Point& point)
	{
		return ClipperPoint(
			to_clipper(point.x),
			to_clipper(point.y));
	}

	inline Point
	from_clipper (const ClipperPoint& point)
	{
		return Point(
			from_clipper(point.x),
			from_clipper(point.y));
	}


	void Polyline_create (
		Polyline* polyline, const ClipperPath& path, bool loop, bool hole = false);

	void Polyline_get_path (
		ClipperPath* path, const Polyline& polyline, bool hole = false);

	bool Polyline_expand (
		Polygon* result, const Polyline& polyline,
		coord width, CapType cap, JoinType join, coord miter_limit);


}// Rays


#endif//EOH
