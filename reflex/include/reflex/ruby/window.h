// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_WINDOW_H__
#define __REFLEX_RUBY_WINDOW_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/window.h>
#include <reflex/ruby/event.h>


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Window)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class window_class ();
	// class Reflex::Window


	template <typename T>
	class RubyWindow : public Rucy::ClassWrapper<T>
	{

		typedef Rucy::ClassWrapper<T> Super;

		public:

			virtual void on_activate (Event* e)
			{
				RUCY_SYM(on_activate);
				if (this->is_overridable())
					this->value.call(on_activate, Rucy::value(e));
				else
					return Super::on_activate(e);
			}

			virtual void on_deactivate (Event* e)
			{
				RUCY_SYM(on_deactivate);
				if (this->is_overridable())
					this->value.call(on_deactivate, Rucy::value(e));
				else
					return Super::on_deactivate(e);
			}

			virtual void on_show (Event* e)
			{
				RUCY_SYM(on_show);
				if (this->is_overridable())
					this->value.call(on_show, Rucy::value(e));
				else
					return Super::on_show(e);
			}

			virtual void on_hide (Event* e)
			{
				RUCY_SYM(on_hide);
				if (this->is_overridable())
					this->value.call(on_hide, Rucy::value(e));
				else
					return Super::on_hide(e);
			}

			virtual void on_close (Event* e)
			{
				RUCY_SYM(on_close);
				if (this->is_overridable())
					this->value.call(on_close, Rucy::value(e));
				else
					return Super::on_close(e);
			}

			virtual void on_update (UpdateEvent* e)
			{
				RUCY_SYM(on_update);
				if (this->is_overridable())
					this->value.call(on_update, Rucy::value(e));
				else
					Super::on_update(e);
			}

			virtual void on_draw (DrawEvent* e)
			{
				RUCY_SYM(on_draw);
				if (this->is_overridable())
					this->value.call(on_draw, Rucy::value(e));
				else
					Super::on_draw(e);
			}

			virtual void on_move (FrameEvent* e)
			{
				RUCY_SYM(on_move);
				if (this->is_overridable())
					this->value.call(on_move, Rucy::value(e));
				else
					Super::on_move(e);
			}

			virtual void on_resize (FrameEvent* e)
			{
				RUCY_SYM(on_resize);
				if (this->is_overridable())
					this->value.call(on_resize, Rucy::value(e));
				else
					Super::on_resize(e);
			}

			virtual void on_key (KeyEvent* e)
			{
				RUCY_SYM(on_key);
				if (this->is_overridable())
					this->value.call(on_key, Rucy::value(e));
				else
					Super::on_key(e);
			}

			virtual void on_key_down (KeyEvent* e)
			{
				RUCY_SYM(on_key_down);
				if (this->is_overridable())
					this->value.call(on_key_down, Rucy::value(e));
				else
					Super::on_key_down(e);
			}

			virtual void on_key_up (KeyEvent* e)
			{
				RUCY_SYM(on_key_up);
				if (this->is_overridable())
					this->value.call(on_key_up, Rucy::value(e));
				else
					Super::on_key_up(e);
			}

			virtual void on_pointer (PointerEvent* e)
			{
				RUCY_SYM(on_pointer);
				if (this->is_overridable())
					this->value.call(on_pointer, Rucy::value(e));
				else
					Super::on_pointer(e);
			}

			virtual void on_pointer_down (PointerEvent* e)
			{
				RUCY_SYM(on_pointer_down);
				if (this->is_overridable())
					this->value.call(on_pointer_down, Rucy::value(e));
				else
					Super::on_pointer_down(e);
			}

			virtual void on_pointer_up (PointerEvent* e)
			{
				RUCY_SYM(on_pointer_up);
				if (this->is_overridable())
					this->value.call(on_pointer_up, Rucy::value(e));
				else
					Super::on_pointer_up(e);
			}

			virtual void on_pointer_move (PointerEvent* e)
			{
				RUCY_SYM(on_pointer_move);
				if (this->is_overridable())
					this->value.call(on_pointer_move, Rucy::value(e));
				else
					Super::on_pointer_move(e);
			}

			virtual void on_pointer_cancel (PointerEvent* e)
			{
				RUCY_SYM(on_pointer_cancel);
				if (this->is_overridable())
					this->value.call(on_pointer_cancel, Rucy::value(e));
				else
					Super::on_pointer_cancel(e);
			}

			virtual void on_wheel (WheelEvent* e)
			{
				RUCY_SYM(on_wheel);
				if (this->is_overridable())
					this->value.call(on_wheel, Rucy::value(e));
				else
					Super::on_wheel(e);
			}

	};// RubyWindow


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Window> ()
	{
		return Reflex::window_class();
	}

	inline Value
	value (Reflex::Window::Ref& ref, Value klass = Reflex::window_class())
	{
		return value(ref.get(), klass);
	}


}// Rucy


#endif//EOH
