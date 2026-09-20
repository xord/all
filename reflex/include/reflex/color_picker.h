// -*- c++ -*-
#pragma once
#ifndef __REFLEX_COLOR_PICKER_H__
#define __REFLEX_COLOR_PICKER_H__


#include <xot/ref.h>
#include <xot/pimpl.h>
#include <reflex/defs.h>
#include <reflex/event.h>


namespace Reflex
{


	class Window;


	class ColorPicker : public Xot::RefCountable<>
	{

		typedef ColorPicker This;

		public:

			typedef Xot::Ref<This> Ref;

			ColorPicker ();

			virtual ~ColorPicker ();

			virtual void pick_color ();

			virtual void pick_color (const Color& initial);

			virtual void      set_owner (Window* window);

			virtual       Window* owner ();

			virtual const Window* owner () const;

			virtual void set_alpha (bool state);

			virtual bool     alpha () const;

			virtual void on_color (ColorEvent* e);

			virtual void on_close (Event* e);

			virtual operator bool () const;

			virtual bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// ColorPicker


}// Reflex


#endif//EOH
