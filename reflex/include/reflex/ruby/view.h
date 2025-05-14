// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_VIEW_H__
#define __REFLEX_RUBY_VIEW_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/view.h>
#include <reflex/ruby/event.h>


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::View)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class view_class ();
	// class Reflex::View


	template <typename T>
	class RubyView : public Rucy::ClassWrapper<T>
	{

		typedef Rucy::ClassWrapper<T> Super;

		public:

			virtual Bounds content_bounds () const
			{
				RUCY_SYM(content_bounds);
				if (this->is_overridable())
				{
					Rucy::Value ret = this->value.call(content_bounds);
					return ret.is_nil() ? Super::content_bounds() : Rucy::to<Bounds>(ret);
				}
				else
					return Super::content_bounds();
			}

			virtual void on_attach (Event* e)
			{
				RUCY_SYM(on_attach);
				if (this->is_overridable())
					this->value.call(on_attach, Rucy::value(e));
				else
					Super::on_attach(e);
			}

			virtual void on_detach (Event* e)
			{
				RUCY_SYM(on_detach);
				if (this->is_overridable())
					this->value.call(on_detach, Rucy::value(e));
				else
					Super::on_detach(e);
			}

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

			virtual void on_zoom (FrameEvent* e)
			{
				RUCY_SYM(on_zoom);
				if (this->is_overridable())
					this->value.call(on_zoom, Rucy::value(e));
				else
					Super::on_zoom(e);
			}

			virtual void on_rotate (FrameEvent* e)
			{
				RUCY_SYM(on_rotate);
				if (this->is_overridable())
					this->value.call(on_rotate, Rucy::value(e));
				else
					Super::on_rotate(e);
			}

			virtual void on_scroll (ScrollEvent* e)
			{
				RUCY_SYM(on_scroll);
				if (this->is_overridable())
					this->value.call(on_scroll, Rucy::value(e));
				else
					Super::on_scroll(e);
			}

			virtual void on_focus (FocusEvent* e)
			{
				RUCY_SYM(on_focus);
				if (this->is_overridable())
					this->value.call(on_focus, Rucy::value(e));
				else
					Super::on_focus(e);
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

			virtual void on_midi (MIDIEvent* e)
			{
				RUCY_SYM(on_midi);
				if (this->is_overridable())
					this->value.call(on_midi, Rucy::value(e));
				else
					Super::on_midi(e);
			}

			virtual void on_note (NoteEvent* e)
			{
				RUCY_SYM(on_note);
				if (this->is_overridable())
					this->value.call(on_note, Rucy::value(e));
				else
					Super::on_note(e);
			}

			virtual void on_note_on (NoteEvent* e)
			{
				RUCY_SYM(on_note_on);
				if (this->is_overridable())
					this->value.call(on_note_on, Rucy::value(e));
				else
					Super::on_note_on(e);
			}

			virtual void on_note_off (NoteEvent* e)
			{
				RUCY_SYM(on_note_off);
				if (this->is_overridable())
					this->value.call(on_note_off, Rucy::value(e));
				else
					Super::on_note_off(e);
			}

			virtual void on_capture (CaptureEvent* e)
			{
				RUCY_SYM(on_capture);
				if (this->is_overridable())
					this->value.call(on_capture, Rucy::value(e));
				else
					Super::on_capture(e);
			}

			virtual void on_timer (TimerEvent* e)
			{
				RUCY_SYM(on_timer);
				if (this->is_overridable())
					this->value.call(on_timer, Rucy::value(e));
				else
					Super::on_timer(e);
			}

			virtual bool will_contact (View* v)
			{
				RUCY_SYM_Q(will_contact);
				if (this->is_overridable())
					return this->value.call(will_contact, Rucy::value(v));
				else
					return Super::will_contact(v);
			}

			virtual void on_contact (ContactEvent* e)
			{
				RUCY_SYM_B(on_contact);
				if (this->is_overridable())
					this->value.call(on_contact, Rucy::value(e));
				else
					Super::on_contact(e);
			}

			virtual void on_contact_begin (ContactEvent* e)
			{
				RUCY_SYM_B(on_contact_begin);
				if (this->is_overridable())
					this->value.call(on_contact_begin, Rucy::value(e));
				else
					Super::on_contact_begin(e);
			}

			virtual void on_contact_end (ContactEvent* e)
			{
				RUCY_SYM_B(on_contact_end);
				if (this->is_overridable())
					this->value.call(on_contact_end, Rucy::value(e));
				else
					Super::on_contact_end(e);
			}

	};// RubyView


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::View> ()
	{
		return Reflex::view_class();
	}

	inline Value
	value (Reflex::View::Ref& ref, Value klass = Reflex::view_class())
	{
		return value(ref.get(), klass);
	}


}// Rucy


#endif//EOH
