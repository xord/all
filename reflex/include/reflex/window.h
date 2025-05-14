// -*- c++ -*-
#pragma once
#ifndef __REFLEX_WINDOW_H__
#define __REFLEX_WINDOW_H__


#include <xot/ref.h>
#include <xot/pimpl.h>
#include <rays/point.h>
#include <rays/bounds.h>
#include <rays/painter.h>
#include <reflex/defs.h>
#include <reflex/event.h>
#include <reflex/screen.h>


namespace Reflex
{


	class View;


	class Window : public Xot::RefCountable<>
	{

		typedef Window This;

		public:

			typedef Xot::Ref<This> Ref;

			enum Flag
			{

				FLAG_CLOSABLE    = Xot::bit(0),

				FLAG_MINIMIZABLE = Xot::bit(1),

				FLAG_RESIZABLE   = Xot::bit(2),

				FLAG_FULLSCREEN  = Xot::bit(3),

				FLAG_PORTRAIT    = Xot::bit(4),

				FLAG_LANDSCAPE   = Xot::bit(5),

				FLAG_LAST        = FLAG_LANDSCAPE

			};// Flag

			Window ();

			virtual void show ();

			virtual void hide ();

			virtual bool hidden () const;

			virtual void close (bool force = false);

			virtual void redraw ();

			virtual Point from_screen (const Point& point) const;

			virtual Point   to_screen (const Point& point) const;

			virtual void    set_title (const char* title);

			virtual const char* title () const;

			virtual void set_frame (coord x, coord y, coord width, coord height);

			virtual void set_frame (const Bounds& bounds);

			virtual Bounds   frame () const;

			virtual void    set_flag (uint flags);

			virtual uint        flags () const;

			virtual void    add_flag (uint flags);

			virtual void remove_flag (uint flags);

			virtual bool    has_flag (uint flags) const;

			virtual Screen screen () const;

			virtual       View* root ();

			virtual const View* root () const;

			virtual       View* focus ();

			virtual const View* focus () const;

			virtual       Painter* painter ();

			virtual const Painter* painter () const;

			virtual void on_activate   (Event* e);

			virtual void on_deactivate (Event* e);

			virtual void on_show (Event* e);

			virtual void on_hide (Event* e);

			virtual void on_close (Event* e);

			virtual void on_update (UpdateEvent* e);

			virtual void on_draw   (DrawEvent* e);

			virtual void on_move   (FrameEvent* e);

			virtual void on_resize (FrameEvent* e);

			virtual void on_key      (KeyEvent* e);

			virtual void on_key_down (KeyEvent* e);

			virtual void on_key_up   (KeyEvent* e);

			virtual void on_pointer        (PointerEvent* e);

			virtual void on_pointer_down   (PointerEvent* e);

			virtual void on_pointer_up     (PointerEvent* e);

			virtual void on_pointer_move   (PointerEvent* e);

			virtual void on_pointer_cancel (PointerEvent* e);

			virtual void on_wheel (WheelEvent* e);

			virtual void on_midi (MIDIEvent* e);

			virtual void on_note     (NoteEvent* e);

			virtual void on_note_on  (NoteEvent* e);

			virtual void on_note_off (NoteEvent* e);

			virtual void on_control_change (ControlChangeEvent* e);

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PImpl<Data> self;

		protected:

			virtual ~Window ();

	};// Window


}// Reflex


#endif//EOH
