// -*- c++ -*-
#pragma once
#ifndef __RAYS_BITMAP_H__
#define __RAYS_BITMAP_H__


#include <xot/pimpl.h>
#include <rays/defs.h>
#include <rays/color_space.h>
#include <rays/font.h>


namespace Rays
{


	class Bitmap
	{

		typedef Bitmap This;

		public:

			Bitmap ();

			Bitmap (
				int width, int height, const ColorSpace& cs = RGBA,
				const void* pixels = NULL);

			~Bitmap ();

			Bitmap dup () const;

			int width () const;

			int height () const;

			const ColorSpace& color_space () const;

			int pitch () const;

			size_t size () const;

			      void* pixels ();

			const void* pixels () const;

			template <typename T>       T* at (int x, int y);

			template <typename T> const T* at (int x, int y) const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Bitmap


	template <typename T> T*
	Bitmap::at (int x, int y)
	{
		return (T*) (((char*) pixels()) + pitch() * y + x * color_space().Bpp());
	}

	template <typename T> const T*
	Bitmap::at (int x, int y) const
	{
		return const_cast<This*>(this)->at<T>(x, y);
	}


}// Rays


#endif//EOH
