#include "application.h"


#include <xot/windows.h>
#include "reflex/exception.h"
#include "window.h"
#include "tray.h"


namespace Reflex
{


	Application::Data*
	Application_create_data ()
	{
		return new Application::Data();
	}

	void
	Application_set_menu (Application* app, Menu* menu)
	{
		Tray_update_icon(app);
	}

	void
	Application_set_background (Application* app, bool state)
	{
		Tray_update_icon(app);
	}

	void
	Application_set_background_menu (Application* app, Menu* menu)
	{
		Tray_update_icon(app);
	}

	void
	Application_quit_if_should ()
	{
		if (Application_should_quit(app()))
			app()->quit();
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
		Tray_update_icon(this);

		Event e;
		Application_call_start(this, &e);

		timeBeginPeriod(1);

		double prev = get_time();

		MSG msg;
		while (true)
		{
			if (PeekMessageW(&msg, NULL, 0, 0, PM_REMOVE))
			{
				if (msg.message == WM_QUIT)
					break;

				if (Window_translate_accelerator(&msg))
					continue;

				TranslateMessage(&msg);
				DispatchMessageW(&msg);
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

		Tray_remove_icon();
		Application_cleanup(this);

		if (msg.wParam != 0)
			reflex_error(__FILE__, __LINE__, "WM_QUIT with wParam %d.", msg.wParam);
	}

	void
	Application::quit ()
	{
		Event e;
		Application_call_quit(this, &e);
		if (e.is_blocked()) return;

		PostQuitMessage(0);
	}

	void
	Application::on_about (Event* e)
	{
	}


}// Reflex
