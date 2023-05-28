// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_OSX_SCREEN_H__
#define __REFLEX_SRC_OSX_SCREEN_H__


#import <AppKit/NSScreen.h>
#include "reflex/screen.h"


namespace Reflex
{


	void Screen_initialize (Screen* pthis, NSScreen* screen);


}// Reflex


#endif//EOH
