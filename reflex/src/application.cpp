#include "application.h"


#include <algorithm>
#include "reflex/exception.h"
#include "reflex/debug.h"


namespace Reflex
{


	namespace global
	{

		static Application* instance = NULL;

	}// global


	Application*
	app ()
	{
		return global::instance;
	}


	void
	Application_add_window (Application* app, Window* window)
	{
		app->self->windows.push_back(window);
	}

	void
	Application_remove_window(Application* app, Window* window)
	{
		auto it = std::find(
			app->self->windows.begin(), app->self->windows.end(), window);
		if (it == app->self->windows.end()) return;

		app->self->windows.erase(it);
	}

	size_t
	Application_count_windows (Application* app)
	{
		return app->self->windows.size();
	}


	Application::Application ()
	:	self(Application_create_data())
	{
		if (global::instance)
			reflex_error(__FILE__, __LINE__, "multiple application instances.");

		global::instance = this;
	}

	Application::~Application ()
	{
		global::instance = NULL;
	}

	void
	Application::set_name (const char* name)
	{
		if (!name)
			argument_error(__FILE__, __LINE__);

		self->name = name;
	}

	const char*
	Application::name () const
	{
		return self->name.c_str();
	}

	Application::window_iterator
	Application::window_begin ()
	{
		return self->windows.begin();
	}

	Application::const_window_iterator
	Application::window_begin () const
	{
		return self->windows.begin();
	}

	Application::window_iterator
	Application::window_end ()
	{
		return self->windows.end();
	}

	Application::const_window_iterator
	Application::window_end () const
	{
		return self->windows.end();
	}

	bool
	Application::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
