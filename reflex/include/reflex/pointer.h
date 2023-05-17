// -*- c++ -*-
#pragma once
#ifndef __REFLEX_POINTER_H__
#define __REFLEX_POINTER_H__


#include <xot/pimpl.h>
#include <xot/util.h>
#include <rays/point.h>
#include <reflex/defs.h>


namespace Reflex
{


	class Pointer
	{

		typedef Pointer This;

		public:

			typedef int ID;

			enum Type
			{

				TYPE_NONE    = 0,

				MOUSE        = Xot::bit(0),

				MOUSE_LEFT   = Xot::bit(1),

				MOUSE_RIGHT  = Xot::bit(2),

				MOUSE_MIDDLE = Xot::bit(3),

				TOUCH        = Xot::bit(4),

				PEN          = Xot::bit(5),

			};// Type

			enum Action
			{

				ACTION_NONE = 0,

				DOWN,

				UP,

				MOVE,

				CANCEL,

				STAY

			};// Action

			Pointer ();

			Pointer (
				ID id, uint type, Action action,
				const Point& position, uint modifiers, bool drag,
				uint click_count, uint layer_index, double time);

			Pointer (const This& obj);

			Pointer& operator = (const This& obj);

			~Pointer ();

			ID id () const;

			uint type () const;

			Action action () const;

			const Point& position () const;

			uint modifiers () const;

			bool is_drag () const;

			uint click_count () const;

			uint layer_index () const;

			double time () const;

			const Pointer* prev () const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PImpl<Data> self;

	};// Pointer


}// Reflex


#endif//EOH
