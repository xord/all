// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WINDOW_H__
#define __REFLEX_SRC_WINDOW_H__


#include <vector>
#include <list>
#include <map>
#include <xot/time.h>
#include <rays/point.h>
#include <rays/painter.h>
#include "reflex/window.h"
#include "reflex/view.h"
#include "pointer.h"


namespace Reflex
{


	typedef std::list<Pointer> PointerList;


	enum {CAPTURE_ALL = INT_MAX};


	struct Window::Data
	{

		struct PointerData
		{

			uint view_index;

			PointerData (uint view_index);

		};// PointerData

		typedef std::map<Pointer::ID, PointerData>    TargetPointerMap;

		typedef std::map<View::Ref, TargetPointerMap> CaptureMap;

		int hide_count = 1;

		bool redraw    = true;

		Painter painter;

		View::Ref root, focus;

		Point prev_position, prev_size;

		double prev_time_update, prev_time_draw, prev_fps = 0;

		CaptureMap captures;

		int next_pointer_id = 1;

		Pointer prev_mouse_pointer;

		PointerList prev_pointers;

		uint flags;

		Data ();

		virtual ~Data ();

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

	uint Window_default_flags ();

	void Window_initialize (Window* window);

	void Window_show (Window* window);

	void Window_hide (Window* window);

	void Window_close (Window* window);

	void        Window_set_title (      Window* window, const char* title);

	const char* Window_get_title (const Window& window);

	void   Window_set_frame (
		Window* window, coord x, coord y, coord width, coord height);

	Bounds Window_get_frame (const Window& window);

	Screen Window_get_screen (const Window& window);

	void Window_set_flags (Window* window, uint flags);

	float Window_get_pixel_density (const Window& window);

	void Window_set_focus (Window* window, View* view);

	void Window_register_capture (
		Window* window, View* view, Pointer::ID target, uint view_index = 0);

	void Window_unregister_capture (
		Window* window, View* view, Pointer::ID target);

	void Window_call_activate_event   (Window* window);

	void Window_call_deactivate_event (Window* window);

	void Window_call_draw_event       (Window* window, DrawEvent*    event);

	void Window_call_key_event        (Window* window, KeyEvent*     event);

	void Window_call_pointer_event    (Window* window, PointerEvent* event);

	void Window_call_wheel_event      (Window* window, WheelEvent*   event);


	typedef View* (*Window_CreateRootViewFun) ();

	void Window_set_create_root_view_fun (Window_CreateRootViewFun fun);


}// Reflex


#endif//EOH
