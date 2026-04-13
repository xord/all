// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_PAINTER_H__
#define __RAYS_SRC_PAINTER_H__


#include "rays/painter.h"


namespace Rays
{


	enum PrimitiveMode
	{

		MODE_NONE           = -1,

		MODE_POINTS         = 0x0,

		MODE_LINES          = 0x1,

		MODE_LINE_LOOP      = 0x2,

		MODE_LINE_STRIP     = 0x3,

		MODE_TRIANGLES      = 0x4,

		MODE_TRIANGLE_STRIP = 0x5,

		MODE_TRIANGLE_FAN   = 0x6,

		MODE_QUADS          = 0x7,

		MODE_QUAD_STRIP     = 0x8,

		MODE_POLYGON        = 0x9,

	};// PrimitiveMode


	void Painter_draw (
		Painter* painter, PrimitiveMode mode, const Color& color,
		const Coord3* points,           size_t npoints,
		const uint*   indices   = NULL, size_t nindices = 0,
		const Coord3* texcoords = NULL);

	void Painter_draw (
		Painter* painter, PrimitiveMode mode,
		const Coord3* points,           size_t npoints,
		const uint*   indices   = NULL, size_t nindices = 0,
		const Color*  colors    = NULL,
		const Coord3* texcoords = NULL);


}// Rays


#endif//EOH
