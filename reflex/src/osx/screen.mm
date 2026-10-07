// -*- mode: objc -*-
#include "screen.h"


#import <AppKit/AppKit.h>
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

	String
	Screen::name () const
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		const char* name = NULL;
		if (@available(macOS 10.15, *))
			name = self->screen.localizedName.UTF8String;

		return name ? name : "";
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

	float
	Screen::pixel_density () const
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		return self->screen.backingScaleFactor;
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

	Screen::List
	Screen::all ()
	{
		List list;
		for (NSScreen* screen in NSScreen.screens)
		{
			Screen s;
			Screen_initialize(&s, screen);
			list.emplace_back(s);
		}
		return list;
	}


}// Reflex
