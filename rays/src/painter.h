// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_PAINTER_H__
#define __RAYS_SRC_PAINTER_H__


#include "rays/painter.h"
#include "opengl.h"


namespace Rays
{


	void Painter_draw (
		Painter* painter, GLenum mode, const Color& color,
		const Coord3* points,           size_t npoints,
		const uint*   indices   = NULL, size_t nindices = 0,
		const Coord3* texcoords = NULL);

	void Painter_draw (
		Painter* painter, GLenum mode,
		const Coord3* points,           size_t npoints,
		const uint*   indices   = NULL, size_t nindices = 0,
		const Color*  colors    = NULL,
		const Coord3* texcoords = NULL);


}// Rays


#endif//EOH
