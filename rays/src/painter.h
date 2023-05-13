// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_PAINTER_H__
#define __RAYS_SRC_PAINTER_H__


#include "rays/painter.h"
#include "opengl.h"


namespace Rays
{


	void Painter_draw_polygon (
		Painter* painter, GLenum mode, const Color& color,
		const Coord3* points,         size_t npoints,
		const uint*   indices = NULL, size_t nindices = 0);


}// Rays


#endif//EOH
