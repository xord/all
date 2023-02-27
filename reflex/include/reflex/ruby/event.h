// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_EVENT_H__
#define __REFLEX_RUBY_EVENT_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/event.h>


namespace Reflex
{


	Rucy::Class event_class ();
	// class Reflex::Event

	Rucy::Class update_event_class ();
	// class Reflex::UpdateEvent

	Rucy::Class draw_event_class ();
	// class Reflex::DrawEvent

	Rucy::Class frame_event_class ();
	// class Reflex::FrameEvent

	Rucy::Class scroll_event_class ();
	// class Reflex::ScrollEvent

	Rucy::Class focus_event_class ();
	// class Reflex::FocusEvent

	Rucy::Class key_event_class ();
	// class Reflex::KeyEvent

	Rucy::Class pointer_event_class ();
	// class Reflex::PointerEvent

	Rucy::Class wheel_event_class ();
	// class Reflex::WheelEvent

	Rucy::Class capture_event_class ();
	// class Reflex::CaptureEvent

	Rucy::Class timer_event_class ();
	// class Reflex::TimerEvent

	Rucy::Class contact_event_class ();
	// class Reflex::ContactEvent

	Rucy::Class motion_event_class ();
	// class Reflex::MotionEvent


}// Reflex


RUCY_DECLARE_VALUE_FROM_TO(Reflex::Event)

RUCY_DECLARE_VALUE_FROM_TO(Reflex::UpdateEvent)

RUCY_DECLARE_VALUE_FROM_TO(Reflex::DrawEvent)

RUCY_DECLARE_VALUE_FROM_TO(Reflex::FrameEvent)

RUCY_DECLARE_VALUE_FROM_TO(Reflex::ScrollEvent)

RUCY_DECLARE_VALUE_FROM_TO(Reflex::FocusEvent)

RUCY_DECLARE_VALUE_FROM_TO(Reflex::KeyEvent)

RUCY_DECLARE_VALUE_FROM_TO(Reflex::PointerEvent)

RUCY_DECLARE_VALUE_FROM_TO(Reflex::WheelEvent)

RUCY_DECLARE_VALUE_FROM_TO(Reflex::CaptureEvent)

RUCY_DECLARE_VALUE_FROM_TO(Reflex::TimerEvent)

RUCY_DECLARE_VALUE_FROM_TO(Reflex::ContactEvent)

RUCY_DECLARE_VALUE_FROM_TO(Reflex::MotionEvent)


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Event> ()
	{
		return Reflex::event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::UpdateEvent> ()
	{
		return Reflex::update_event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::DrawEvent> ()
	{
		return Reflex::draw_event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::FrameEvent> ()
	{
		return Reflex::frame_event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::ScrollEvent> ()
	{
		return Reflex::scroll_event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::FocusEvent> ()
	{
		return Reflex::focus_event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::KeyEvent> ()
	{
		return Reflex::key_event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::PointerEvent> ()
	{
		return Reflex::pointer_event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::WheelEvent> ()
	{
		return Reflex::wheel_event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::CaptureEvent> ()
	{
		return Reflex::capture_event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::TimerEvent> ()
	{
		return Reflex::timer_event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::ContactEvent> ()
	{
		return Reflex::contact_event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::MotionEvent> ()
	{
		return Reflex::motion_event_class();
	}


}// Rucy


#endif//EOH
