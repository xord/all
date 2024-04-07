// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_COORD_H__
#define __RAYS_SRC_COORD_H__


#include <glm/vec2.hpp>
#include <glm/vec3.hpp>
#include "rays/coord.h"


namespace Rays
{


	typedef glm::vec<3, coord, glm::defaultp> Vec3;

	typedef glm::vec<4, coord, glm::defaultp> Vec4;


	inline       Vec3& to_glm (      Coord3& val) {return *(      Vec3*) &val;}

	inline const Vec3& to_glm (const Coord3& val) {return *(const Vec3*) &val;}

	template <typename T>
	inline       T&    to_rays (      Vec3&  val) {return *(      T*)    &val;}

	template <typename T>
	inline const T&    to_rays (const Vec3&  val) {return *(const T*)    &val;}


}// Rays


#endif//EOH
