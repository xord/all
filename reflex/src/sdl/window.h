#pragma once
#ifndef __REFLEX_SRC_SDL_WINDOW_H__
#define __REFLEX_SRC_SDL_WINDOW_H__


#include <SDL.h>
#include "../window.h"


namespace Reflex
{


	Window* Window_from (SDL_Window* native);

	bool Window_dispatch_event (Window* win, const SDL_Event& event);

	void Window_update (Window* win);


}// Reflex


#endif//EOH
