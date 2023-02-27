// -*- c++ -*-
#pragma once
#ifndef __RAYS_COLOR_H__
#define __RAYS_COLOR_H__


#include <xot/util.h>
#include <rays/defs.h>
#include <rays/coord.h>


namespace Rays
{


	class ColorSpace;


	struct Color : public Coord4
	{

		typedef Color This;

		typedef Coord4 Super;

		Color (float gray = 0,                     float alpha = 1);

		Color (float red, float green, float blue, float alpha = 1);

		Color (void* pixel, const ColorSpace& cs);

		Color dup () const;

		Color& reset (float gray = 0,                     float alpha = 1);

		Color& reset (float red, float green, float blue, float alpha = 1);

		Color& reset8 (int gray = 0,                 int alpha = 255);

		Color& reset8 (int red, int green, int blue, int alpha = 255);

		Color& reset (const void* pixel, const ColorSpace& cs);

		void     get (      void* pixel, const ColorSpace& cs) const;

		operator bool () const;

		bool operator ! () const;

		friend bool operator == (const This& lhs, const This& rhs);

		friend bool operator != (const This& lhs, const This& rhs);

		static uchar float2uchar (float value)
		{
			return (uchar) Xot::clip(0.f, 255.f, value * 255);
		}

		static float uchar2float (int value)
		{
			return value / 255.f;
		}

	};// Color


	Color gray  (float gray, float alpha = 1);

	Color gray8 (int   gray, int   alpha = 255);

	Color rgb  (float red, float green, float blue, float alpha = 1);

	Color rgb8 (int   red, int   green, int   blue, int   alpha = 255);

	Color hsv (float hue, float saturation, float value, float alpha = 1);


}// Rays


#endif//EOH
