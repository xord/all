// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_VIEW_H__
#define __REFLEX_SRC_VIEW_H__


#include "reflex/view.h"


namespace Reflex
{


	constexpr const char* VIEW_TAG_ROOT = "ROOT";


	class Body;


	void View_set_window (View* view, Window* window);

	void View_set_frame (View* view, const Bounds& frame);

	const Style& View_get_style (const View* view);

	Body* View_get_body (View* view, bool create = true);

	bool View_is_active (const View& view);

	void View_update_tree (View* view, const UpdateEvent& event);

	void View_draw_tree (
		View* view, DrawEvent* event, const Point& offset, const Bounds& clip);

	void View_update_styles (View* view, const Selector& selector);

	void View_update_shapes (View* view);

	void View_call_key_event     (View* view, KeyEvent* event);

	void View_call_pointer_event (View* view, PointerEvent* event);

	void View_call_wheel_event   (View* view, WheelEvent* event);

	void View_call_note_event    (View* view, NoteEvent* event);

	void View_call_contact_event (View* view, ContactEvent* event);


}// Reflex


#endif//EOH
