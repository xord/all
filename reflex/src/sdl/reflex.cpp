#include "reflex/reflex.h"


#include <SDL.h>
#include "reflex/exception.h"
#include "../vk.h"


namespace Reflex
{


	namespace global
	{

		static bool initialized = false;

	}// global


	void
	init ()
	{
		if (global::initialized)
			reflex_error(__FILE__, __LINE__, "already initialized.");

#if SDL_VERSION_ATLEAST(2, 0, 22)
		// without this, sdl cuts a composition longer than 32 bytes into
		// pieces and reuses the offset field to say where each piece goes,
		// which leaves no way to tell a composition from its selection
		SDL_SetHint(SDL_HINT_IME_SUPPORT_EXTENDED_TEXT, "1");
#endif

		global::initialized = true;
	}

	void
	fin ()
	{
		if (!global::initialized)
			reflex_error(__FILE__, __LINE__, "not initialized.");

		global::initialized = false;
	}

	void
	alert (const char* message, const char* title)
	{
		if (!message)
			argument_error(__FILE__, __LINE__);

		int ret = SDL_ShowSimpleMessageBox(
			SDL_MESSAGEBOX_INFORMATION, title ? title : "", message, NULL);
		if (ret < 0)
			reflex_error(__FILE__, __LINE__, SDL_GetError());
	}


}// Reflex
