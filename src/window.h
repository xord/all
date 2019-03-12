// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WINDOW_H__
#define __REFLEX_SRC_WINDOW_H__


#include <map>
#include <xot/time.h>
#include <rays/point.h>
#include <rays/painter.h>
#include <reflex/window.h>
#include <reflex/view.h>


namespace Reflex
{


	struct Window::Data
	{

		typedef std::map<View::Ref, bool> CapturingViews;

		int hide_count = 1;

		bool redraw = true;

		Painter painter;

		View::Ref root, focus;

		Point prev_position, prev_size;

		double prev_time_update, prev_time_draw, prev_fps = 0;

		CapturingViews capturing_views;

		Data ()
		{
			prev_time_update = prev_time_draw = Xot::time();
		}

		virtual ~Data ()
		{
		}

		virtual bool is_valid () const = 0;

		operator bool () const
		{
			return is_valid();
		}

		bool operator ! () const
		{
			return !operator bool();
		}

	};// Window::Data


	Window::Data* Window_create_data ();

	void Window_initialize (Window* window);

	void Window_show (Window* window);

	void Window_hide (Window* window);

	void Window_close (Window* window);

	void        Window_set_title (      Window* window, const char* title);

	const char* Window_get_title (const Window& window);

	void   Window_set_frame (
		Window* window, coord x, coord y, coord width, coord height);

	Bounds Window_get_frame (const Window& window);


	typedef View* (*CreateRootViewFun) ();

	void set_create_root_view_fun (CreateRootViewFun fun);

	View* create_root_view ();

	void set_focus (Window* window, View* view);

	void register_capture   (View* view);

	void unregister_capture (View* view);


}// Reflex


#endif//EOH
