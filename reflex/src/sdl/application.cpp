#include "../application.h"


#include <SDL.h>
#ifdef WASM
	#include <emscripten.h>
#endif
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

	void
	Application_stop (Application* app)
	{
		get_data(app)->quit = true;
	}

	void
	Application_set_menu (Application* app, Menu* menu)
	{
	}

	void
	Application_set_background (Application* app, bool state)
	{
	}

	void
	Application_set_background_menu (Application* app, Menu* menu)
	{
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

	static void
	dispatch_events (Application* app)
	{
		SDL_Event event;
		while (SDL_PollEvent(&event))
		{
			bool dispatched = dispatch_window_event(event);

#if SDL_VERSION_ATLEAST(2, 0, 22)
			// the text of an extended composition event is handed over to
			// whoever takes the event, so it is freed here rather than in the
			// window that may or may not have been found for it
			if (event.type == SDL_TEXTEDITING_EXT)
				SDL_free(event.editExt.text);
#endif

			if (!dispatched && event.type == SDL_QUIT)
				Application_call_quit(app);
		}
	}

	static void
	update_all_windows (Application* app)
	{
		for (auto it = app->window_begin(), end = app->window_end(); it != end; ++it)
			Window_update(it->get());
	}

	static void
	main_loop (Application* app)
	{
		ApplicationData* self = get_data(app);

		double prev = Xot::time();
		while (!self->quit)
		{
			dispatch_events(app);

			static const double INTERVAL  = 1.0 / 60.0;
			static const double SLEEPABLE = INTERVAL * 0.9;

			double now = Xot::time();
			double dt  = now - prev;
			if (dt < INTERVAL)
			{
				if (dt < SLEEPABLE) SDL_Delay(1);
				continue;
			}

			update_all_windows(app);
			prev = now;
		}
	}

#ifdef WASM
	static void
	emscripten_main_loop (void* arg)
	{
		Application* app = (Application*) arg;

		dispatch_events(app);

		if (get_data(app)->quit)
		{
			emscripten_cancel_main_loop();
			Application_cleanup(app);
		}
		else
			update_all_windows(app);
	}
#endif

	void
	Application::start ()
	{
		get_data(this)->quit = false;
		self->started        = false;
		self->quitting       = false;
		self->running        = true;

		Event e;
		Application_call_start_event(this, &e);

#ifdef WASM
		emscripten_set_main_loop_arg(emscripten_main_loop, this, 0, true);
#else
		// guarded here too, since rays can throw while drawing
		Application_guard([&]()
		{
			main_loop(this);
		});
		self->running = false;

		Application_cleanup(this);
		Application_throw_exception(this);
#endif
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
