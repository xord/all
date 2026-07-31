#include "reflex/clipboard.h"


#include <SDL.h>
#include "reflex/exception.h"


namespace Reflex
{


	void
	set_clipboard (const Clipboard& clipboard)
	{
		const char* text = clipboard.text();
		if (SDL_SetClipboardText(text ? text : "") != 0)
			reflex_error(__FILE__, __LINE__, SDL_GetError());
	}

	Clipboard
	get_clipboard ()
	{
		Clipboard clipboard;

		if (SDL_HasClipboardText() == SDL_TRUE)
		{
			char* text = SDL_GetClipboardText();
			if (text)
			{
				clipboard.set_text(text);
				SDL_free(text);
			}
		}

		return clipboard;
	}


}// Reflex
