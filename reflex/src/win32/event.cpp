#include "event.h"


#include <windowsx.h>


namespace Reflex
{

#if 0
	static int
	get_points (Points* points, UINT msg, WPARAM wp, LPARAM lp)
	{
		if (!points) return false;

		switch (msg)
		{
			case WM_LBUTTONDBLCLK:
				points->count += 1;
			case WM_LBUTTONDOWN:
			case WM_LBUTTONUP:
				points->type   = POINT_MOUSE_LEFT;
				points->count += 1;
				break;

			case WM_RBUTTONDBLCLK:
				points->count += 1;
			case WM_RBUTTONDOWN:
			case WM_RBUTTONUP:
				points->type   = POINT_MOUSE_RIGHT;
				points->count += 1;
				break;

			case WM_MBUTTONDBLCLK:
				points->count += 1;
			case WM_MBUTTONDOWN:
			case WM_MBUTTONUP:
				points->type   = POINT_MOUSE_MIDDLE;
				points->count += 1;
				break;
		}

		return get_modifiers(&points->modifiers);
	}
#endif

	NativePointerEvent::NativePointerEvent (UINT msg, WPARAM wp, LPARAM lp)
	//:	PointerEvent(POINT_NONE, GET_X_LPARAM(lp), GET_Y_LPARAM(lp))
	{
		//get_points(this, msg, wp, lp);
	}


	NativeWheelEvent::NativeWheelEvent (UINT msg, WPARAM wp, LPARAM lp)
	//:	WheelEvent()
	{
	}


}// Reflex
