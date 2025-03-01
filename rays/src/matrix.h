// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_MATRIX_H__
#define __RAYS_SRC_MATRIX_H__


#include "rays/matrix.h"
#include "glm.h"


namespace Rays
{


	typedef glm::mat<4, 4, coord> Mat4;


	inline       Mat4&   to_glm (      Matrix& val) {return *(      Mat4*)   &val;}

	inline const Mat4&   to_glm (const Matrix& val) {return *(const Mat4*)   &val;}

	inline       Matrix& to_rays (      Mat4&  val) {return *(      Matrix*) &val;}

	inline const Matrix& to_rays (const Mat4&  val) {return *(const Matrix*) &val;}


}// Rays


#endif//EOH
