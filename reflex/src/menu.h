// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_MENU_H__
#define __REFLEX_SRC_MENU_H__


#include <memory>
#include <rays/image.h>
#include "reflex/menu.h"
#include "selector.h"


namespace Reflex
{


	struct Menu::Data
	{

		Xot::WeakRef<Menu> parent;

		String label;

		Image image;

		KeyCode key    = KEY_NONE;

		uint modifiers = MOD_NONE;

		bool enabled   = true;

		bool checked   = false;

		bool separator = false;

		std::unique_ptr<ChildList> pchildren;

		SelectorPtr pselector;

		Data ();

		virtual ~Data ();

		ChildList* children ()
		{
			if (!pchildren) pchildren.reset(new ChildList);
			return pchildren.get();
		}

	};// Menu::Data


	Menu::Data* Menu_create_data ();

	void Menu_validate_shortcut_modifiers (uint modifiers);

	void Menu_update (Menu* menu);

	void Menu_popup (Menu* menu, View* view, coord x, coord y);

	void Menu_child_added   (Menu* parent, Menu* child, int index);

	void Menu_child_removed (Menu* parent, Menu* child);

	void Menu_cancel_active_pointers_for_popup (View* view);

	void Menu_call_click_event         (Menu* menu, Event* event);

	void Menu_call_show_event          (Menu* menu, Event* event);

	void Menu_call_hide_event          (Menu* menu, Event* event);

	void Menu_call_open_submenu_event  (Menu* menu, Event* event);

	void Menu_call_close_submenu_event (Menu* menu, Event* event);


}// Reflex


#endif//EOH
