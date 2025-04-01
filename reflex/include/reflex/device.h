// -*- c++ -*-
#pragma once
#ifndef __REFLEX_DEVICE_H__
#define __REFLEX_DEVICE_H__


#include <xot/ref.h>
#include <reflex/defs.h>


namespace Reflex
{


	class Device : public Xot::RefCountable<>
	{

		public:

			typedef Xot::Ref<Device> Ref;

			virtual ~Device ();

			virtual const char* name () const = 0;

			virtual operator bool () const;

			bool operator ! () const;

	};// Device


	void vibrate ();


}// Reflex


#endif//EOH
