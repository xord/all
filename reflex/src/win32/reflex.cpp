#include "reflex/reflex.h"


#include <xot/windows.h>
#include "reflex/exception.h"
#include "../rays.h"


namespace Reflex
{


	static struct ReflexLoaded
	{
		ReflexLoaded ()
		{
			Rays::Rays_set_pre_init_fun(pre_init);
		}

		static void pre_init ()
		{
			// enable High DPI: before Rays makes the hidden window for its OpenGL
			// context, as Windows takes no declaration after a window
			SetProcessDPIAware();
		}

	} reflex_loaded;


	namespace global
	{

		static bool initialized     = false;

		static bool com_initialized = false;

	}// global


	void
	init ()
	{
		if (global::initialized)
			reflex_error(__FILE__, __LINE__, "already initialized.");
		global::initialized = true;

		global::com_initialized =
			SUCCEEDED(CoInitializeEx(NULL, COINIT_APARTMENTTHREADED));
	}

	void
	fin ()
	{
		if (!global::initialized)
			reflex_error(__FILE__, __LINE__, "not initialized.");
		global::initialized = false;

		if (global::com_initialized)
		{
			CoUninitialize();
			global::com_initialized = false;
		}
	}

	void
	alert (const char* message, const char* title)
	{
		if (!message)
			argument_error(__FILE__, __LINE__);

		MessageBoxW(
			GetActiveWindow(),
			String(message)           .to_wstr().c_str(),
			String(title ? title : "").to_wstr().c_str(),
			MB_OK | MB_ICONINFORMATION | MB_TASKMODAL);
	}


}// Reflex
