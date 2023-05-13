// -*- c++ -*-
#pragma once
#ifndef __RAYS_EXT_DEFS_H__
#define __RAYS_EXT_DEFS_H__


#include <vector>
#include <rucy.h>
#include "rays/defs.h"
#include "rays/point.h"
#include "rays/ruby/defs.h"


using namespace Rucy;

using Rays::coord;


void get_line_args (
	std::vector<Rays::Point>* points,
	int argc, const Value* argv);

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


#endif//EOH
