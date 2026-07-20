// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WIN32_MENU_H__
#define __REFLEX_SRC_WIN32_MENU_H__


#include <xot/windows.h>
#include "../menu.h"


namespace Reflex
{


	HMENU Menu_get_hmenu (Menu* menu);

	void Menu_call_command_event (HMENU hmenu, uint index);

	void Menu_call_open_event  (HMENU hmenu);

	void Menu_call_close_event (HMENU hmenu);


}// Reflex


#endif//EOH
