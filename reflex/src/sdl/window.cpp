#include "window.h"


#include "reflex/exception.h"
#include "reflex/debug.h"
#include "reflex/screen.h"
#include "../view.h"
#include "screen.h"
#include "opengl.h"


namespace Reflex
{


	static const char* WINDOW_DATA_KEY = "reflex/pwindow";


	struct WindowData : public Window::Data
	{

		SDL_Window* native = NULL;

		OpenGLContext context;

		mutable String title_tmp;

		WindowData ()
		{
		}

		~WindowData ()
		{
			destroy();
		}

		void create (Window* win)
		{
			native = SDL_CreateWindow(
				"", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 0, 0,
				to_sdl_flags(flags));
			if (!native)
				reflex_error(__FILE__, __LINE__, SDL_GetError());

			SDL_SetWindowData(native, WINDOW_DATA_KEY, win);

			context.init(native);

			Window_register(win);
		}

		void destroy ()
		{
			if (!native) return;

			context.fin();

			Window* win = Window_from(native);
			if (win) Window_unregister(win);

			SDL_SetWindowData(native, WINDOW_DATA_KEY, NULL);
			SDL_DestroyWindow(native);
			native = NULL;

			if (Window_all().empty())
				Reflex::app()->quit();
		}

		Uint32 to_sdl_flags (uint flags)
		{
			Uint32 sdl_flags = SDL_WINDOW_OPENGL;

			if (Xot::has_flag(flags, Window::FLAG_RESIZABLE))
				sdl_flags |= SDL_WINDOW_RESIZABLE;

			if (Xot::has_flag(flags, Window::FLAG_FULLSCREEN))
				sdl_flags |= SDL_WINDOW_FULLSCREEN_DESKTOP;

			return sdl_flags;
		}

		bool is_valid () const override
		{
			return native;
		}

	};// WindowData


	static WindowData*
	get_data (Window* win)
	{
		return (WindowData*) win->self.get();
	}

	static const WindowData*
	get_data (const Window* win)
	{
		return get_data(const_cast<Window*>(win));
	}

	static SDL_Window*
	get_native (Window* win)
	{
		SDL_Window* native = get_data(win)->native;
		if (!native)
			invalid_state_error(__FILE__, __LINE__);

		return native;
	}

	static const SDL_Window*
	get_native (const Window* win)
	{
		return get_native(const_cast<Window*>(win));
	}

	static void
	draw (Window* win)
	{
		WindowData* self = get_data(win);

		double now = Xot::time();
		double dt  = now - self->prev_time_draw;
		double fps = 1. / dt;

		fps = self->prev_fps * 0.9 + fps * 0.1;// LPF

		self->prev_time_draw = now;
		self->prev_fps       = fps;

		Reflex::DrawEvent e(dt, fps);
		Window_call_draw_event(win, &e);
	}

	static void
	frame_changed (Window* win)
	{
		Rays::Bounds b           = win->frame();
		Rays::Point dpos         = b.position() - win->self->prev_position;
		Rays::Point dsize        = b.size()     - win->self->prev_size;
		win->self->prev_position = b.position();
		win->self->prev_size     = b.size();

		if (dpos == 0 && dsize == 0) return;

		Reflex::FrameEvent e(b, dpos.x, dpos.y, 0, dsize.x, dsize.y, 0);
		if (dpos  != 0) win->on_move(&e);
		if (dsize != 0)
		{
			Rays::Bounds b = win->frame();
			b.move_to(0, 0);

			if (win->painter())
				win->painter()->canvas(b, win->painter()->pixel_density());

			if (win->root())
				View_set_frame(win->root(), b);

			win->on_resize(&e);
		}
	}


	Window::Data*
	Window_create_data ()
	{
		return new WindowData();
	}

	uint
	Window_default_flags ()
	{
		return
			Window::FLAG_CLOSABLE  |
			Window::FLAG_RESIZABLE |
			Window::FLAG_MINIMIZABLE;
	}

	void
	Window_initialize (Window* win)
	{
		get_data(win)->create(win);
	}

	void
	Window_show (Window* win)
	{
		if (!*win)
			invalid_state_error(__FILE__, __LINE__);

		SDL_ShowWindow(get_native(win));
	}

	void
	Window_hide (Window* win)
	{
		if (!*win)
			invalid_state_error(__FILE__, __LINE__);

		SDL_HideWindow(get_native(win));
	}

	void
	Window_close (Window* win)
	{
		if (!*win)
			invalid_state_error(__FILE__, __LINE__);

		get_data(win)->destroy();
	}

	void
	Window_set_title (Window* win, const char* title)
	{
		if (!title)
			argument_error(__FILE__, __LINE__);

		if (!*win) return;

		SDL_SetWindowTitle(get_native(win), title);
	}

	const char*
	Window_get_title (const Window& win)
	{
		if (!win) return "";

		const WindowData* self = get_data(&win);
		const char* title      = SDL_GetWindowTitle(self->native);
		self->title_tmp        = title ? title : "";
		return self->title_tmp.c_str();
	}

	void
	Window_set_frame (Window* win, coord x, coord y, coord w, coord h)
	{
		if (!*win) return;

		SDL_Window* native = get_native(win);
		SDL_SetWindowPosition(native, (int) x, (int) y);
		SDL_SetWindowSize(    native, (int) w, (int) h);
	}

	Bounds
	Window_get_frame (const Window& win)
	{
		if (!win)
			invalid_state_error(__FILE__, __LINE__);

		SDL_Window* native = get_native(const_cast<Window*>(&win));
		int x, y, w, h;
		SDL_GetWindowPosition(native, &x, &y);
		SDL_GetWindowSize(    native, &w, &h);
		return Bounds(x, y, w, h);
	}

	Screen
	Window_get_screen (const Window& win)
	{
		if (!win)
			return Screen();

		SDL_Window* native = get_native(const_cast<Window*>(&win));
		int display_index  = SDL_GetWindowDisplayIndex(native);
		if (display_index < 0)
			return Screen();

		Screen s;
		Screen_initialize(&s, display_index);
		return s;
	}

	void
	Window_set_flags (Window* win, uint flags)
	{
		if (!*win)
			invalid_state_error(__FILE__, __LINE__);

		WindowData* self = get_data(win);
		Uint32 sdl_flags = self->to_sdl_flags(flags);

		SDL_SetWindowResizable(
			self->native,
			sdl_flags & SDL_WINDOW_RESIZABLE ? SDL_TRUE : SDL_FALSE);

		int result = SDL_SetWindowFullscreen(
			self->native,
			sdl_flags & SDL_WINDOW_FULLSCREEN_DESKTOP ? SDL_WINDOW_FULLSCREEN_DESKTOP : 0);
		if (result != 0)
			reflex_error(__FILE__, __LINE__, SDL_GetError());
	}

	float
	Window_get_pixel_density (const Window& win)
	{
		if (!win)
			return 1;

		SDL_Window* native = get_native(const_cast<Window*>(&win));
		int display_index  = SDL_GetWindowDisplayIndex(native);
		if (display_index < 0)
			return 1;

		float dpi = 0;
		if (SDL_GetDisplayDPI(display_index, &dpi, NULL, NULL) != 0)
			return 1;

		return dpi / 96.f;
	}

	Window*
	Window_from (SDL_Window* native)
	{
		return (Window*) SDL_GetWindowData(native, WINDOW_DATA_KEY);
	}

	bool
	Window_dispatch_event (Window* win, const SDL_Event& event)
	{
		if (event.type != SDL_WINDOWEVENT) return true;

		WindowData* self = get_data(win);

		switch (event.window.event)
		{
			case SDL_WINDOWEVENT_CLOSE:
				Window_close(win);
				break;

			case SDL_WINDOWEVENT_EXPOSED:
			{
				self->context.make_current();
				draw(win);
				self->context.swap_buffers();
				break;
			}

			case SDL_WINDOWEVENT_MOVED:
			case SDL_WINDOWEVENT_RESIZED:
			case SDL_WINDOWEVENT_SIZE_CHANGED:
			case SDL_WINDOWEVENT_RESTORED:
			case SDL_WINDOWEVENT_MAXIMIZED:
			case SDL_WINDOWEVENT_MINIMIZED:
				frame_changed(win);
				break;
		}

		return true;
	}

	static void
	redraw_window (SDL_Window* native)
	{
		SDL_Event e;
		e.type            = SDL_WINDOWEVENT;
		e.window.event    = SDL_WINDOWEVENT_EXPOSED;
		e.window.windowID = SDL_GetWindowID(native);
		SDL_PushEvent(&e);
	}

	void
	Window_update (Window* win)
	{
		WindowData* self = get_data(win);

		Window_call_update_event(win);

		if (self->redraw)
		{
			redraw_window(self->native);
			self->redraw = false;
		}
	}


}// Reflex
