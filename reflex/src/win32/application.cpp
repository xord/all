#include "reflex/application.h"


#include <windows.h>
#include "reflex/exception.h"


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


	struct Application::Data
	{

		String name;

	};// Application::Data


	Application::Application ()
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
	Application::start ()
	{
		Event e;
		on_start(&e);

		MSG msg;
		while (GetMessage(&msg, NULL, 0, 0))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}

		if (msg.wParam != 0)
			reflex_error(__FILE__, __LINE__, "WM_QUIT with wParam %d.", msg.wParam);
	}

	void
	Application::quit ()
	{
		PostQuitMessage(0);
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

	void
	Application::on_start (Event* e)
	{
	}

	void
	Application::on_quit (Event* e)
	{
	}

	void
	Application::on_motion (MotionEvent* e)
	{
	}

	void
	Application::on_preference (Event* e)
	{
	}

	void
	Application::on_about (Event* e)
	{
	}

	Application::operator bool () const
	{
		return true;
	}

	bool
	Application::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
