#include "application.h"


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

	bool
	Application::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
