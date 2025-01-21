#include "application.h"


#include "reflex/exception.h"
#include "reflex/debug.h"
#include "window.h"


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
		return Window_all().begin();
	}

	Application::const_window_iterator
	Application::window_begin () const
	{
		return Window_all().begin();
	}

	Application::window_iterator
	Application::window_end ()
	{
		return Window_all().end();
	}

	Application::const_window_iterator
	Application::window_end () const
	{
		return Window_all().end();
	}

	bool
	Application::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
