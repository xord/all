// -*- mode: objc -*-
#include "screen.h"


#include "reflex/exception.h"


namespace Reflex
{


	struct Screen::Data
	{

		UIScreen* screen = nil;

		~Data ()
		{
			if (screen) [screen release];
		}

	};// Screen::Data


	void
	Screen_initialize (Screen* pthis, UIScreen* screen)
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

		CGRect b = self->screen.bounds;
		return Bounds(b.origin.x, b.origin.y, b.size.width, b.size.height);
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
