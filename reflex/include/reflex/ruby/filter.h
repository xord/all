// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_FILTER_H__
#define __REFLEX_RUBY_FILTER_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <rays/ruby/image.h>
#include <rays/ruby/painter.h>
#include <reflex/filter.h>


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Filter)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class filter_class ();
	// class Reflex::Filter


	template <typename T>
	class RubyFilter : public Rucy::ClassWrapper<T>
	{

		typedef Rucy::ClassWrapper<T> Super;

		public:

			virtual void apply (Painter* painter, const Image& image) const
			{
				RUCY_SYM(apply);
				if (this->is_overridable())
					this->value.call(apply, Rucy::value(painter), Rucy::value(image));
				else
					Super::apply(painter, image);
			}

	};// RubyFilter


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Filter> ()
	{
		return Reflex::filter_class();
	}

	inline Value
	value (Reflex::Filter::Ref& ref, Value klass = Reflex::filter_class())
	{
		return value(ref.get(), klass);
	}


}// Rucy


#endif//EOH
