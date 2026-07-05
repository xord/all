// -*- c++ -*-
#pragma once
#ifndef __REFLEX_PIN_H__
#define __REFLEX_PIN_H__


#include <xot/pimpl.h>
#include <rays/point.h>
#include <reflex/defs.h>


namespace Reflex
{


	class View;
	class SnapConstraint;
	class LinkConstraint;
	class RailConstraint;
	class ChaseConstraint;


	class Pin
	{

		public:

			Pin ();

			Pin (coord x, coord y);

			Pin (const Point& position);

			Pin (View* view);

			Pin (View* view, coord x, coord y);

			Pin (View* view, const Point& position);

			SnapConstraint*  snap  (Pin target = Pin());

			LinkConstraint*  link  (Pin target = Pin());

			RailConstraint*  rail  (Pin target = Pin());

			ChaseConstraint* chase (Pin target = Pin());

			      View* view ();

			const View* view () const;

			const Point* position () const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Pin


}// Reflex


#endif//EOH
