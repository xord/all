// -*- c++ -*-
#pragma once
#ifndef __RAYS_DEFS_H__
#define __RAYS_DEFS_H__


#define GLM_FORCE_CXX03


#include <xot/defs.h>
#include <xot/string.h>


#if defined(WIN32) && defined(GCC) && defined(RAYS)
	#define RAYS_EXPORT __declspec(dllexport)
#else
	#define RAYS_EXPORT
#endif


namespace Rays
{


	using namespace Xot::Types;

	using Xot::String;


	typedef float coord;


	enum CapType
	{

		CAP_BUTT = 0,

		CAP_ROUND,

		CAP_SQUARE,

		CAP_TYPE_MAX,

		CAP_DEFAULT = CAP_BUTT

	};// CapType


	enum JoinType
	{

		JOIN_MITER = 0,

		JOIN_ROUND,

		JOIN_SQUARE,

		JOIN_TYPE_MAX,

		JOIN_DEFAULT             = JOIN_MITER,
		JOIN_DEFAULT_MITER_LIMIT = 2

	};// JoinType


	enum BlendMode
	{

		BLEND_NORMAL = 0,

		BLEND_ADD,

		BLEND_SUBTRACT,

		BLEND_LIGHTEST,

		BLEND_DARKEST,

		BLEND_EXCLUSION,

		BLEND_MULTIPLY,

		BLEND_SCREEN,

		BLEND_REPLACE,

		BLEND_MODE_MAX

	};// BlendMode


	enum TexCoordMode
	{

		TEXCOORD_IMAGE = 0,

		TEXCOORD_NORMAL,

		TEXCOORD_MODE_MAX

	};// TexCoordMode


	enum TexCoordWrap
	{

		TEXCOORD_CLAMP = 0,

		TEXCOORD_REPEAT,

		TEXCOORD_WRAP_MAX

	};// TexCoordWrap


}// Rays


#endif//EOH
