#include "application.h"


#include "reflex/exception.h"
#include "reflex/debug.h"
#include "window.h"
#include "gamepad.h"


namespace Reflex
{


	namespace global
	{

		static Application* instance = NULL;

	}// global


	void
	Application_call_start (Application* app, Event* e)
	{
		Gamepad_init(app);

		app->on_start(e);
	}

	void
	Application_call_quit (Application* app, Event* e)
	{
		app->on_quit(e);
		if (e->is_blocked()) return;

		Gamepad_fin(app);
	}

	void
	Application_call_device_connect (Application* app, Device* device)
	{
		DeviceEvent e(device);
		app->on_device_connect(&e);
	}

	void
	Application_call_device_disconnect (Application* app, Device* device)
	{
		DeviceEvent e(device);
		app->on_device_disconnect(&e);
	}

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

	void
	Application::on_start (Event* e)
	{
	}

	void
	Application::on_quit (Event* e)
	{
	}

	void
	Application::on_device_connect (DeviceEvent* e)
	{
	}

	void
	Application::on_device_disconnect (DeviceEvent* e)
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
