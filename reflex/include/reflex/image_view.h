// -*- c++ -*-
#pragma once
#ifndef __REFLEX_IMAGE_VIEW_H__
#define __REFLEX_IMAGE_VIEW_H__


#include <xot/pimpl.h>
#include <rays/image.h>
#include <reflex/view.h>


namespace Reflex
{


	class ImageView : public View
	{

		typedef View Super;

		public:

			ImageView (const char* name = NULL);

			virtual ~ImageView ();

			virtual void  set_image (Image image);

			virtual Image get_image () const;

			virtual Bounds content_bounds () const;

			virtual void on_draw (DrawEvent* e);

			struct Data;

			Xot::PImpl<Data> self;

	};// ImageView


}// Reflex


#endif//EOH
