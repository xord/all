// -*- c++ -*-
#pragma once
#ifndef __RAYS_EXT_DEFS_H__
#define __RAYS_EXT_DEFS_H__


#include <vector>
#include <rucy.h>
#include "rays/defs.h"
#include "rays/color.h"
#include "rays/point.h"
#include "rays/ruby/defs.h"


using namespace Rucy;

using Rays::coord;


void get_points (std::vector<Rays::Point>* points, int argc, const Value* argv);

void get_colors (std::vector<Rays::Color>* colors, int argc, const Value* argv);

void get_rect_args (
	coord* x,  coord* y,  coord* w,  coord* h,
	coord* lt, coord* rt, coord* lb, coord* rb, uint* nseg,
	int argc, const Value* argv,
	Value round, Value lefttop, Value righttop, Value leftbottom, Value rightbottom,
	Value nsegment);

void get_ellipse_args (
	coord* x, coord* y, coord* w, coord* h,
	Rays::Point* hole_size, float* from, float* to, uint* nseg,
	int argc, const Value* argv,
	Value center, Value radius, Value hole, Value angel_from, Value angle_to,
	Value nsegment);


struct CreateParams
{

	std::vector<Rays::Point> points;

	std::vector<Rays::Color> colors;

	std::vector<Rays::Point> texcoords;

	CreateParams (
		const Value& points_, const Value& colors_, const Value& texcoords_)
	{
		get_points(&points, points_.size(), points_.as_array());

		if (colors_)
			get_colors(&colors, colors_.size(), colors_.as_array());

		if (texcoords_)
			get_points(&texcoords, texcoords_.size(), texcoords_.as_array());
	}

	const Rays::Point* ppoints () const
	{
		return points.empty() ? NULL : &points[0];
	}

	const Rays::Color* pcolors () const
	{
		return colors.empty() ? NULL : &colors[0];
	}

	const Rays::Point* ptexcoords () const
	{
		return texcoords.empty() ? NULL : &texcoords[0];
	}

	size_t size () const
	{
		return points.size();
	}

};// CreateParams


#endif//EOH
