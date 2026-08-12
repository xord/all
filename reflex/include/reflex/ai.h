// -*- c++ -*-
#pragma once
#ifndef __REFLEX_AI_H__
#define __REFLEX_AI_H__


#include <xot/pimpl.h>
#include <reflex/defs.h>


namespace Reflex
{


	class AI
	{

		public:

			AI (const char* system_prompt = NULL);

			~AI ();

			String generate (const char* prompt);

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// AI


}// Reflex


#endif//EOH
