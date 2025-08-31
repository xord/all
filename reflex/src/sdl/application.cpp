#include "../application.h"


#include <SDL.h>
#include <xot/time.h>
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "window.h"


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

	static const ApplicationData*
	get_data (const Application* app)
	{
		return get_data(const_cast<Application*>(app));
	}

	Application::Data*
	Application_create_data ()
	{
		return new ApplicationData();
	}


	static bool
	dispatch_window_event (const SDL_Event& event)
	{
		SDL_Window* native = SDL_GetWindowFromID(event.key.windowID);
		if (!native) return false;

		Window* win = Window_from(native);
		if (!win) return false;

		return Window_dispatch_event(win, event);
	}

	static bool
	dispatch_events ()
	{
		SDL_Event event;
		while (SDL_PollEvent(&event))
		{
			if (dispatch_window_event(event))
				continue;

			switch (event.type)
			{
				case SDL_QUIT: return false;
			}
		}

		return true;
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
		Application_call_start(this, &e);

		ApplicationData* self = get_data(this);

		double prev = Xot::time();
		while (!self->quit)
		{
			if (!dispatch_events()) break;

			static const double INTERVAL  = 1.0 / 60.0;
			static const double SLEEPABLE = INTERVAL * 0.9;

			double now = Xot::time();
			double dt  = now - prev;
			if (dt < INTERVAL)
			{
				if (dt < SLEEPABLE) SDL_Delay(1);
				continue;
			}

			update_all_windows(this);
			prev = now;
		}
	}

	void
	Application::quit ()
	{
		Event e;
		Application_call_quit(this, &e);
		if (e.is_blocked()) return;

		get_data(this)->quit = true;
	}

	void
	Application::on_about (Event* e)
	{
	}


}// Reflex
