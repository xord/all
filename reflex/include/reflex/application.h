// -*- c++ -*-
#pragma once
#ifndef __REFLEX_APPLICATION_H__
#define __REFLEX_APPLICATION_H__


#include <xot/ref.h>
#include <xot/pimpl.h>
#include <reflex/defs.h>
#include <reflex/event.h>


namespace Reflex
{


	class Application : public Xot::RefCountable<>
	{

		typedef Application This;

		public:

			typedef Xot::Ref<This> Ref;

			Application ();

			virtual void start ();

			virtual void quit ();

			virtual void    set_name (const char* name);

			virtual const char* name () const;

			virtual void on_start (Event* e);

			virtual void on_quit (Event* e);

			virtual void on_motion (MotionEvent* e);

			virtual void on_preference (Event* e);

			virtual void on_about (Event* e);

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PImpl<Data> self;

		protected:

			virtual ~Application ();

	};// Application


	Application* app ();


}// Reflex


#endif//EOH
