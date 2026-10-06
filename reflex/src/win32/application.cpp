#include "application.h"


#include <vector>
#include <xot/windows.h>
#include "reflex/exception.h"
#include "window.h"
#include "tray.h"


namespace Reflex
{


	struct ApplicationData : public Application::Data
	{

		bool quit = false;

	};// ApplicationData


	static ApplicationData*
	get_data (Application* app)
	{
		return (ApplicationData*) app->self.get();
	}

	Application::Data*
	Application_create_data ()
	{
		return new ApplicationData();
	}

	static std::wstring
	get_app_executable_path ()
	{
		std::wstring path(MAX_PATH, L'\0');
		while (true)
		{
			DWORD len = GetModuleFileNameW(NULL, &path[0], (DWORD) path.size());
			if (len < path.size())
			{
				path.resize(len);
				break;
			}
			path.resize(path.size() * 2);
		}
		return path;
	}

	static String
	get_product_name (const wchar_t* path)
	{
		DWORD size = GetFileVersionInfoSizeW(path, NULL);
		if (size == 0) return "";

		std::vector<BYTE> info(size);
		if (!GetFileVersionInfoW(path, 0, size, &info[0]))
			return "";

		struct Translation {WORD lang, codepage;};
		Translation* translations = NULL;
		UINT bytes                = 0;
		if (
			!VerQueryValueW(
				&info[0], L"\\VarFileInfo\\Translation", (void**) &translations, &bytes) ||
			bytes < sizeof(Translation))
		{
			return "";
		}

		LANGID deflang           = GetUserDefaultUILanguage();
		const Translation* found = &translations[0];
		for (size_t i = 0; i < bytes / sizeof(Translation); ++i)
		{
			const Translation& t = translations[i];
			if (t.lang == deflang)
			{
				found = &t;
				break;
			}
			if (
				PRIMARYLANGID(t.lang) == PRIMARYLANGID(deflang) &&
				found == &translations[0])
			{
				found = &t;
			}
		}

		wchar_t key[64];
		swprintf(
			key, 64, L"\\StringFileInfo\\%04x%04x\\ProductName",
			found->lang, found->codepage);

		wchar_t* name = NULL;
		if (!VerQueryValueW(&info[0], key, (void**) &name, &bytes) || bytes <= 1)
			return "";

		return String(name, wcslen(name));
	}

	String
	Application_get_default_name ()
	{
		std::wstring path = get_app_executable_path();
		if (path.empty())
			return "";

		String name = get_product_name(path.c_str());
		if (!name.empty())
			return name;

		std::wstring file = path.substr(path.find_last_of(L"\\/") + 1);
		size_t dot        = file.find_last_of(L'.');
		if (dot != std::wstring::npos) file.resize(dot);
		return String(file.c_str(), file.size());
	}

	void
	Application_stop (Application* app)
	{
		get_data(app)->quit = true;
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
			Application_call_quit(app());
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
		ApplicationData* self = get_data(this);
		self->quit     = false;
		self->quitting = false;
		self->started  = false;
		self->running  = true;

		Tray_update_icon(this);

		Event e;
		Application_call_start_event(this, &e);

		timeBeginPeriod(1);

		double prev = get_time();

		MSG msg = {0};
		while (!self->quit)
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

				// guarded here too, since rays can throw while drawing
				Application_guard([&]()
				{
					update_all_windows(this);
				});
				prev = now;
			}
		}

		timeEndPeriod(1);

		self->running = false;

		Tray_remove_icon();
		Application_cleanup(this);
		Application_throw_exception(this);

		if (msg.message == WM_QUIT && msg.wParam != 0)
			reflex_error(__FILE__, __LINE__, "WM_QUIT with wParam %d.", msg.wParam);
	}

	void
	Application::quit ()
	{
		Event e;
		Application_call_quit_event(this, &e);
		if (e.is_blocked()) return;

		Application_stop(this);
	}

	void
	Application::on_about (Event* e)
	{
	}


}// Reflex
