// -*- c++ -*-
#pragma once
#ifndef __RUCY_RUBY_H__
#define __RUCY_RUBY_H__


#include <ruby.h>


#ifdef memcpy
#undef memcpy // avoid defining ruby_nonempty_memcpy
#endif


namespace Rucy
{


	typedef VALUE RubyValue;

	typedef int   RubyValueType;

	typedef ID    RubySymbol;


}// Rucy


#endif//EOH
