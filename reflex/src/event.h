// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_EVENT_H__
#define __REFLEX_SRC_EVENT_H__


#include <functional>
#include "reflex/event.h"


namespace Reflex
{


	void DrawEvent_set_view    (DrawEvent* pthis, View* view);

	void DrawEvent_set_painter (DrawEvent* pthis, Painter* painter);

	void DrawEvent_set_bounds  (DrawEvent* pthis, const Bounds& bounds);


	void KeyEvent_set_captured (KeyEvent* pthis, bool captured);


	void PointerEvent_add_pointer    (PointerEvent* pthis, const Pointer& pointer);

	void PointerEvent_erase_pointer  (PointerEvent* pthis, Pointer::ID id);

	Pointer& PointerEvent_pointer_at (PointerEvent* pthis, size_t index);

	void PointerEvent_each_pointer (
		const PointerEvent* pthis, std::function<void(const Pointer&)> fun);

	void PointerEvent_increment_layer_indices (PointerEvent* pthis);

	void PointerEvent_set_captured (PointerEvent* pthis, bool captured);

	void PointerEvent_update_for_child_view (PointerEvent* pthis, const View* view);

	void PointerEvent_update_for_capturing_view (PointerEvent* pthis, const View* view);


	void WheelEvent_set_position (WheelEvent* pthis, const Point& position);


}// Reflex


#endif//EOH
