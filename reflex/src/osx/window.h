// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_OSX_WINDOW_H__
#define __REFLEX_SRC_OSX_WINDOW_H__


#import <AppKit/NSWindow.h>
#include "../window.h"


@class NativeWindow;


namespace Reflex
{


	struct WindowData : public Window::Data
	{

		NativeWindow* native = nil;

		mutable String title_tmp;

		bool is_valid () const
		{
			return native;
		}

	};// WindowData


	      WindowData& Window_get_data (Window* window);

	const WindowData& Window_get_data (const Window* window);

	NSWindowStyleMask Window_make_style_mask (
		uint flags, NSWindowStyleMask styleMask = 0);


}// Reflex


#endif//EOH
