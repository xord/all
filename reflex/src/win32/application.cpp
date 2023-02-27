#include "reflex/application.h"


#include <windows.h>
#include "reflex/exception.h"


namespace Reflex
{


	static Application* instance = NULL;


	Application*
	app ()
	{
		return instance;
	}


	struct Application::Data
	{

		String name;

		operator bool () const
		{
			return true;
		}

	};// Application::Data


	Application::Application ()
	{
		if (instance) reflex_error("multiple application instance.");

		instance = this;
	}

	Application::~Application ()
	{
		instance = NULL;
	}

	bool
	Application::run ()
	{
		if (!*this) return false;

		MSG msg;
		while (GetMessage(&msg, NULL, 0, 0))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}

		return msg.wParam == 0;
	}

	bool
	Application::quit ()
	{
		if (!*this) return false;

		PostQuitMessage(0);
		return true;
	}

	bool
	Application::preference ()
	{
		return *this;
	}

	bool
	Application::about ()
	{
		return *this;
	}

	bool
	Application::set_name (const char* name)
	{
		if (!*this || !name) return false;
		self->name = name;
		return true;
	}

	const char*
	Application::name () const
	{
		if (!*this) return "";
		return self->name.c_str();
	}

	Application::operator bool () const
	{
		return self && *self;
	}

	bool
	Application::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
