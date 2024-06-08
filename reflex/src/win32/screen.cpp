#include "screen.h"


#include "reflex/exception.h"


namespace Reflex
{


	struct Screen::Data
	{

		HMONITOR handle = NULL;

	};// Screen::Data


	void
	Screen_initialize (Screen* pthis, HWND hwnd)
	{
		pthis->self->handle = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONULL);
	}


	Screen::Screen ()
	{
	}

	Screen::~Screen ()
	{
	}

	Bounds
	Screen::frame () const
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		MONITORINFO mi = {0};
		mi.cbSize      = sizeof(mi);
		if (!GetMonitorInfo(self->handle, &mi))
			system_error(__FILE__, __LINE__);

		const auto& r = mi.rcMonitor;
		return Bounds(r.left, r.top, r.right - r.left, r.bottom - r.top);
	}

	Screen::operator bool () const
	{
		return self->handle;
	}

	bool
	Screen::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
