// -*- c++ -*-
#pragma once
#ifndef __REFLEX_TIMER_H__
#define __REFLEX_TIMER_H__


#include <xot/ref.h>
#include <xot/pimpl.h>
#include <reflex/defs.h>
#include <reflex/selector.h>


namespace Reflex
{


	class View;


	class Timer : public Xot::RefCountable<>, public HasSelector
	{

		typedef Timer This;

		public:

			typedef Xot::Ref<This> Ref;

			enum {ID_INVALID = 0, ID_FIRST};

			Timer ();

			virtual ~Timer ();

			virtual void fire ();

			virtual void stop ();

			virtual View* owner () const;

			virtual int id () const;

			virtual float interval () const;

			virtual void set_count (int count);

			virtual int      count () const;

			virtual bool is_finished () const;

			virtual operator bool () const;

			virtual bool operator ! () const;

			friend bool operator == (const This& lhs, const This& rhs);

			friend bool operator != (const This& lhs, const This& rhs);

			struct Data;

			Xot::PImpl<Data> self;

		protected:

			virtual SelectorPtr* get_selector_ptr ();

	};// Timer


}// Reflex


#endif//EOH
