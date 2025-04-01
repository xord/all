#include "../application.h"


#include <xot/windows.h>
#include "reflex/exception.h"
#include "window.h"


namespace Reflex
{


	Application::Data*
	Application_create_data ()
	{
		return new Application::Data();
	}


	static double
	get_time ()
	{
		static const double FREQUENCY_INV = []() {
			LARGE_INTEGER freq;
			QueryPerformanceFrequency(&freq);
			return 1.0 / (double) freq.QuadPart;
		}();

		LARGE_INTEGER counter;
		QueryPerformanceCounter(&counter);
		return (double) counter.QuadPart * FREQUENCY_INV;
	}

	static void
	update_all_windows (Application* app)
	{
		for (auto it = app->window_begin(), end = app->window_end(); it != end; ++it)
			Window_update(it->get());
	}

	void
	Application::start ()
	{
		Event e;
		on_start(&e);

		timeBeginPeriod(1);

		double prev = get_time();

		MSG msg;
		while (true)
		{
			if (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE))
			{
				if (msg.message == WM_QUIT) break;
				TranslateMessage(&msg);
				DispatchMessage(&msg);
			}
			else
			{
				static const double INTERVAL  = 1.0 / 60.0;
				static const double SLEEPABLE = INTERVAL * 0.9;

				double now = get_time();
				double dt  = now - prev;
				if (dt < INTERVAL)
				{
					if (dt < SLEEPABLE) Sleep(1);
					continue;
				}

				update_all_windows(this);
				prev = now;
			}
		}

		timeEndPeriod(1);

		if (msg.wParam != 0)
			reflex_error(__FILE__, __LINE__, "WM_QUIT with wParam %d.", msg.wParam);
	}

	void
	Application::quit ()
	{
		PostQuitMessage(0);
	}

	void
	Application::on_about (Event* e)
	{
	}


}// Reflex
