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

	String
	Screen::name () const
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		const char* name = SDL_GetDisplayName(self->display_index);
		return name ? name : "";
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

	float
	Screen::pixel_density () const
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		return 1;
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

	Screen::List
	Screen::all ()
	{
		int count = SDL_GetNumVideoDisplays();
		if (count < 0)
			reflex_error(__FILE__, __LINE__, SDL_GetError());

		List list;
		for (int i = 0; i < count; ++i)
		{
			Screen s;
			Screen_initialize(&s, i);
			list.emplace_back(s);
		}
		return list;
	}


}// Reflex
