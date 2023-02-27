// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_POLYGON_H__
#define __RAYS_SRC_POLYGON_H__


#include <vector>
#include <rays/polygon.h>


namespace Rays
{


	class Painter;
	struct Color;


	void Polygon_fill (
		const Polygon& polygon, Painter* painter, const Color& color);

	void Polygon_stroke (
		const Polygon& polygon, Painter* painter, const Color& color);

	bool Polygon_triangulate (
		Polygon::TrianglePointList* triangles, const Polygon& polygon);


}// Rays


#endif//EOH
