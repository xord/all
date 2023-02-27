// -*- c++ -*-
#pragma once
#ifndef __RAYS_COLOR_SPACE_H__
#define __RAYS_COLOR_SPACE_H__


#include <rays/defs.h>


namespace Rays
{


	enum ColorSpaceType
	{

		COLORSPACE_UNKNOWN = 0,

		 GRAY_8,  GRAY_16,  GRAY_24,  GRAY_32,  GRAY_float,

		ALPHA_8, ALPHA_16, ALPHA_24, ALPHA_32, ALPHA_float,

		RGB_888, RGBA_8888, RGBX_8888, ARGB_8888, XRGB_8888,

		BGR_888, BGRA_8888, BGRX_8888, ABGR_8888, XBGR_8888,

		RGB_float, RGBA_float, ARGB_float,

		BGR_float, BGRA_float, ABGR_float,

		COLORSPACE_MAX,

		GRAY  =  GRAY_8,

		ALPHA = ALPHA_8,

		RGB   =  RGB_888,  BGR  =  BGR_888,

		RGBA  = RGBA_8888, RGBX = RGBX_8888, ARGB = ARGB_8888, XRGB = XRGB_8888,

		BGRA  = BGRA_8888, BGRX = BGRX_8888, ABGR = ABGR_8888, XBGR = XBGR_8888,

		DEFAULT_COLOR_SPACE = RGBA

	};// ColorSpaceType


	class ColorSpace
	{

		public:

			ColorSpace ();

			ColorSpace (ColorSpaceType type, bool premultiplied = true);

			ColorSpaceType type () const;

			int bpc () const;

			int Bpc () const;

			int bpp () const;

			int Bpp () const;

			int alpha_pos () const;

			bool is_gray () const;

			bool is_alpha () const;

			bool is_rgb () const;

			bool is_bgr () const;

			bool is_float () const;

			bool has_alpha () const;

			bool has_skip () const;

			bool is_alpha_first () const;

			bool is_alpha_last () const;

			bool is_skip_first () const;

			bool is_skip_last () const;

			bool is_premult () const;

			operator bool () const;

			bool operator ! () const;

		private:

			ColorSpaceType type_;

			bool premult;

	};// ColorSpace


}// Rays


#endif//EOH
