// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_COLOR_PICKER_H__
#define __REFLEX_RUBY_COLOR_PICKER_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/color_picker.h>
#include <reflex/ruby/event.h>


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::ColorPicker)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class color_picker_class ();
	// class Reflex::ColorPicker


	template <typename T>
	class RubyColorPicker : public Rucy::ClassWrapper<T>
	{

		typedef Rucy::ClassWrapper<T> Super;

		public:

			virtual void on_color (ColorEvent* e)
			{
				if (this->is_overridable())
				{
					RUCY_SYM(call_color_block);
					this->value.call(call_color_block, Rucy::value(e));

					if (!e->is_blocked())
					{
						RUCY_SYM(on_color);
						this->value.call(on_color, Rucy::value(e));
					}
				}
				else
					Super::on_color(e);
			}

			virtual void on_close (Event* e)
			{
				if (this->is_overridable())
				{
					RUCY_SYM(clear_color_block);
					this->value.call(clear_color_block);

					RUCY_SYM(on_close);
					this->value.call(on_close, Rucy::value(e));
				}
				else
					Super::on_close(e);
			}

	};// RubyColorPicker


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::ColorPicker> ()
	{
		return Reflex::color_picker_class();
	}

	inline Value
	value (Reflex::ColorPicker::Ref& ref, Value klass = Reflex::color_picker_class())
	{
		return value(ref.get(), klass);
	}


}// Rucy


#endif//EOH
