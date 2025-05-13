// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_EVENT_H__
#define __REFLEX_RUBY_EVENT_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/event.h>


RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Event)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::DeviceEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::UpdateEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::DrawEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::FrameEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::ScrollEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::FocusEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::KeyEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::PointerEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::WheelEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::MIDIEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::NoteEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::CaptureEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::TimerEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::ContactEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::MotionEvent)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class event_class ();
	// class Reflex::Event

	REFLEX_EXPORT Rucy::Class device_event_class ();
	// class Reflex::DeviceEvent

	REFLEX_EXPORT Rucy::Class update_event_class ();
	// class Reflex::UpdateEvent

	REFLEX_EXPORT Rucy::Class draw_event_class ();
	// class Reflex::DrawEvent

	REFLEX_EXPORT Rucy::Class frame_event_class ();
	// class Reflex::FrameEvent

	REFLEX_EXPORT Rucy::Class scroll_event_class ();
	// class Reflex::ScrollEvent

	REFLEX_EXPORT Rucy::Class focus_event_class ();
	// class Reflex::FocusEvent

	REFLEX_EXPORT Rucy::Class key_event_class ();
	// class Reflex::KeyEvent

	REFLEX_EXPORT Rucy::Class pointer_event_class ();
	// class Reflex::PointerEvent

	REFLEX_EXPORT Rucy::Class wheel_event_class ();
	// class Reflex::WheelEvent

	REFLEX_EXPORT Rucy::Class midi_event_class ();
	// class Reflex::MIDIEvent

	REFLEX_EXPORT Rucy::Class note_event_class ();
	// class Reflex::NoteEvent

	REFLEX_EXPORT Rucy::Class capture_event_class ();
	// class Reflex::CaptureEvent

	REFLEX_EXPORT Rucy::Class timer_event_class ();
	// class Reflex::TimerEvent

	REFLEX_EXPORT Rucy::Class contact_event_class ();
	// class Reflex::ContactEvent

	REFLEX_EXPORT Rucy::Class motion_event_class ();
	// class Reflex::MotionEvent


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Event> ()
	{
		return Reflex::event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::DeviceEvent> ()
	{
		return Reflex::device_event_class();
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
	get_ruby_class<Reflex::MIDIEvent> ()
	{
		return Reflex::midi_event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::NoteEvent> ()
	{
		return Reflex::note_event_class();
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
