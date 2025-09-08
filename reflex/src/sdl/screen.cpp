#include "screen.h"


#include <SDL.h>
#include "reflex/exception.h"


namespace Reflex
{


	struct Screen::Data
	{

		int display_index = -1;

	};// Screen::Data


	void
	Screen_initialize (Screen* pthis, int display_index)
	{
		if (!pthis)
			argument_error(__FILE__, __LINE__);

		pthis->self->display_index = display_index;
	}


	Screen::Screen ()
	{
	}

	Screen::~Screen ()
	{
	}

	Bounds
	Screen::frame () const
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		SDL_Rect rect;
		if (SDL_GetDisplayBounds(self->display_index, &rect) != 0)
			reflex_error(__FILE__, __LINE__, SDL_GetError());

		return Bounds(rect.x, rect.y, rect.w, rect.h);
	}

	Screen::operator bool () const
	{
		return self->display_index >= 0;
	}

	bool
	Screen::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
