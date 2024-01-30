// -*- mode: objc -*-
#include "screen.h"


#include "reflex/exception.h"


namespace Reflex
{


	struct Screen::Data
	{

		NSScreen* screen = nil;

		~Data ()
		{
			if (screen) [screen release];
		}

	};// Screen::Data


	CGFloat
	primary_screen_height ()
	{
		return NSScreen.screens.firstObject.frame.size.height;
	}

	void
	Screen_initialize (Screen* pthis, NSScreen* screen)
	{
		pthis->self->screen = [screen retain];
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

		NSRect f = self->screen.frame;
		return Bounds(
			f.origin.x,
			primary_screen_height() - (f.origin.y + f.size.height),
			f.size.width,
			f.size.height);
	}

	Screen::operator bool () const
	{
		return self->screen;
	}

	bool
	Screen::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
