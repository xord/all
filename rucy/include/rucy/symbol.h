// -*- c++ -*-
#pragma once
#ifndef __RUCY_SYMBOL_H__
#define __RUCY_SYMBOL_H__


#include <rucy/ruby.h>


#define RUCY_SYMBOL(name, str) static const Rucy::Symbol name (str)

#define RUCY_SYM(s)   RUCY_SYMBOL(s, #s)
#define RUCY_SYM_Q(s) RUCY_SYMBOL(s, #s "?")
#define RUCY_SYM_B(s) RUCY_SYMBOL(s, #s "!")


namespace Rucy
{


	class Value;


	class Symbol
	{

		public:

			Symbol ();

			Symbol (const char* s);

			Symbol (const char* s, size_t len);

			Symbol (RubySymbol symbol);

			RubySymbol symbol () const;

			Value value () const;

			const char* c_str () const;

			operator bool () const;

			bool operator ! () const;

			friend bool operator == (const Symbol& lhs, const Symbol& rhs);

			friend bool operator != (const Symbol& lhs, const Symbol& rhs);

		private:

			RubySymbol sym;

	};// Symbol


}// Rucy


#endif//EOH
