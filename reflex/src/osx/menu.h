// -*- objc -*-
#pragma once
#ifndef __REFLEX_SRC_OSX_MENU_H__
#define __REFLEX_SRC_OSX_MENU_H__


#import <AppKit/NSMenu.h>
#include "../menu.h"


namespace Reflex
{


	NSMenu* Menu_get_nssubmenu (Menu* menu);

	void Menu_set_native_action (Menu* menu, SEL action);

	void Menu_apply_to_main_menu (Menu* menu);


}// Reflex


#endif//EOH
