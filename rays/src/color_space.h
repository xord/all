// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_COLOR_SPACE_H__
#define __RAYS_SRC_COLOR_SPACE_H__


#include <rays/color_space.h>
#include "opengl.h"


namespace Rays
{


	void ColorSpace_get_gl_format_and_type (
		GLenum* format, GLenum* type, const ColorSpace& cs);


}// Rays


#endif//EOH
