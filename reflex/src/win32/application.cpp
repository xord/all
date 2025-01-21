#include "../application.h"


#include <xot/windows.h>
#include "reflex/exception.h"


namespace Reflex
{


	Application::Data*
	Application_create_data ()
	{
		return new Application::Data();
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


}// Reflex
