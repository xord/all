// -*- c++ -*-
#pragma once
#ifndef __RUCY_CLASS_H__
#define __RUCY_CLASS_H__


#include <rucy/module.h>


namespace Rucy
{


	class Class : public Module
	{

		typedef Module Super;

		public:

			Class (RubyValue v = nil());

			void define_alloc_func (RubyFunction0 fun);

			void define_alloc_func (const char* name, RubyFunction0 fun);
			// for RUBY_METHOD macro

			void define_clear_override_flags (RubyFunction0 fun);

	};// Class


}// Rucy


#endif//EOH
