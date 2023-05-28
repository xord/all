// -*- mode: objc -*-
#include "screen.h"


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
		NSRect frame = self->screen.frame;
		return Bounds(
			frame.origin.x,   frame.origin.y,
			frame.size.width, frame.size.height);
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
