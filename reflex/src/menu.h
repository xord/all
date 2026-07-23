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

		String label, key;

		Image image;

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

	void Menu_update (Menu* menu);

	void Menu_popup (Menu* menu, View* view, coord x, coord y);

	void Menu_child_added   (Menu* parent, Menu* child, int index);

	void Menu_child_removed (Menu* parent, Menu* child);


}// Reflex


#endif//EOH
