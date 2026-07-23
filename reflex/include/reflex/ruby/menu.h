// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_MENU_H__
#define __REFLEX_RUBY_MENU_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/menu.h>
#include <reflex/ruby/event.h>


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Menu)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class menu_class ();
	// class Reflex::Menu


	template <typename T>
	class RubyMenu : public Rucy::ClassWrapper<T>
	{

		typedef Rucy::ClassWrapper<T> Super;

		public:

			virtual void on_show (Event* e)
			{
				RUCY_SYM(on_show);
				if (this->is_overridable())
					this->value.call(on_show, Rucy::value(e));
				else
					Super::on_show(e);
			}

			virtual void on_hide (Event* e)
			{
				RUCY_SYM(on_hide);
				if (this->is_overridable())
					this->value.call(on_hide, Rucy::value(e));
				else
					Super::on_hide(e);
			}

			virtual void on_open_submenu (Event* e)
			{
				RUCY_SYM(on_open_submenu);
				if (this->is_overridable())
					this->value.call(on_open_submenu, Rucy::value(e));
				else
					Super::on_open_submenu(e);
			}

			virtual void on_close_submenu (Event* e)
			{
				RUCY_SYM(on_close_submenu);
				if (this->is_overridable())
					this->value.call(on_close_submenu, Rucy::value(e));
				else
					Super::on_close_submenu(e);
			}

			virtual void on_click (Event* e)
			{
				RUCY_SYM(on_click);
				if (this->is_overridable())
					this->value.call(on_click, Rucy::value(e));
				else
					Super::on_click(e);
			}

	};// RubyMenu


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Menu> ()
	{
		return Reflex::menu_class();
	}

	inline Value
	value (Reflex::Menu::Ref& ref, Value klass = Reflex::menu_class())
	{
		return value(ref.get(), klass);
	}


}// Rucy


#endif//EOH
