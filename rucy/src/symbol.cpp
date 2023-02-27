// -*- c++ -*-
#include "rucy/symbol.h"


#include "rucy/rucy.h"
#include "rucy/value.h"


namespace Rucy
{


	Symbol::Symbol ()
	:	sym(0)
	{
	}

	Symbol::Symbol (const char* s)
	:	sym(rb_intern(s))
	{
	}

	Symbol::Symbol (const char* s, size_t len)
	:	sym(rb_intern2(s, len))
	{
	}

	Symbol::Symbol (RubySymbol symbol)
	:	sym(symbol)
	{
	}

	RubySymbol
	Symbol::symbol () const
	{
		return sym;
	}

	Value
	Symbol::value () const
	{
		if (sym == 0) return nil();
		return ID2SYM(sym);
	}

	const char*
	Symbol::c_str () const
	{
		return rb_id2name(sym);
	}

	Symbol::operator bool () const
	{
		return sym != 0;
	}

	bool
	Symbol::operator ! () const
	{
		return !operator bool();
	}

	bool
	operator == (const Symbol& lhs, const Symbol& rhs)
	{
		return lhs.sym == rhs.sym;
	}

	bool
	operator != (const Symbol& lhs, const Symbol& rhs)
	{
		return !operator==(lhs, rhs);
	}


}// Rucy
