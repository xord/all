#include "menu.h"


#include <string>
#include <vector>
#include "reflex/exception.h"
#include "reflex/event.h"
#include "reflex/view.h"
#include "../rays.h"
#include "window.h"


namespace Reflex
{


	static UINT
	next_menu_id ()
	{
		static UINT id = 100;
		return id++;
	}

	static HMENU
	create_hmenu (Menu* menu, bool menubar)
	{
		HMENU hmenu = menubar ? CreateMenu() : CreatePopupMenu();
		if (!hmenu)
			system_error(__FILE__, __LINE__);

		MENUINFO mi   = {sizeof(mi)};
		mi.fMask      = MIM_MENUDATA | MIM_STYLE;
		mi.dwMenuData = (ULONG_PTR) menu;
		mi.dwStyle    = MNS_NOTIFYBYPOS;
		SetMenuInfo(hmenu, &mi);

		return hmenu;
	}

	static void
	destroy_hmenu (HMENU hmenu)
	{
		if (!hmenu || !IsMenu(hmenu)) return;

		while (GetMenuItemCount(hmenu) > 0)
			RemoveMenu(hmenu, 0, MF_BYPOSITION);

		DestroyMenu(hmenu);
	}


	struct MenuData : public Menu::Data
	{

		UINT id        = next_menu_id();

		HMENU hparent  = NULL;

		HMENU hsubmenu = NULL;

		bool menubar   = false;

		bool modified  = false;

		Image image;

		std::shared_ptr<HBITMAP__> hbitmap;

		virtual ~MenuData ()
		{
			destroy_hmenu(hsubmenu);
		}

		HMENU get_hsubmenu (Menu* menu, bool menubar = false);

		HBITMAP get_hbitmap (const Image& image)
		{
			if (image != this->image)
			{
				this->image = image;
				if (image)
					hbitmap.reset(Rays::Bitmap_get_hbitmap(image.bitmap()), DeleteObject);
				else
					hbitmap.reset();
			}
			return hbitmap.get();
		}

	};// MenuData


	static MenuData&
	get_data (Menu* menu)
	{
		if (!menu)
			argument_error(__FILE__, __LINE__);

		return (MenuData&) *menu->self;
	}

	static Menu*
	get_root (Menu* menu)
	{
		while (menu->parent()) menu = menu->parent();
		return menu;
	}

	static void
	set_modified (Menu* menu)
	{
		get_data(get_root(menu)).modified = true;
	}

	static Menu*
	get_item_owner (HMENU hparent, uint index)
	{
		if (!hparent) return NULL;

		MENUITEMINFOW mii = {sizeof(mii)};
		mii.fMask         = MIIM_DATA;
		if (!GetMenuItemInfoW(hparent, index, TRUE, &mii))
			return NULL;

		return (Menu*) mii.dwItemData;
	}

	static Menu*
	get_submenu_owner (HMENU hsubmenu)
	{
		if (!hsubmenu) return NULL;

		MENUINFO mi = {sizeof(mi)};
		mi.fMask    = MIM_MENUDATA;
		if (!GetMenuInfo(hsubmenu, &mi))
			return NULL;

		return (Menu*) mi.dwMenuData;
	}

	static void
	insert_item (HMENU hparent, Menu* item, int index)
	{
		MenuData& self = get_data(item);

		MENUITEMINFOW mii = {sizeof(mii)};
		mii.fMask         = MIIM_ID | MIIM_DATA | MIIM_FTYPE | MIIM_STRING;
		mii.fType         = MFT_STRING;
		mii.wID           = self.id;
		mii.dwItemData    = (ULONG_PTR) item;
		mii.dwTypeData    = (LPWSTR) L"";

		if (!InsertMenuItemW(hparent, (UINT) index, TRUE, &mii))
			system_error(__FILE__, __LINE__);

		self.hparent = hparent;

		Menu_update(item);
	}

	Menu::Data*
	Menu_create_data ()
	{
		return new MenuData();
	}

	void
	Menu_validate_shortcut_modifiers (uint modifiers)
	{
		static const uint SUPPORTED =
			MOD_SHIFT | MOD_CONTROL | MOD_ALT | MOD_OPTION;

		if (modifiers & ~SUPPORTED)
		{
			argument_error(
				__FILE__, __LINE__,
				"modifiers 0x%X can not be used for a shortcut on Windows.",
				modifiers & ~SUPPORTED);
		}
	}

	static String
	get_shortcut_key_name (int key)
	{
		if (key < 0) return "";

		UINT vsc = MapVirtualKeyW((UINT) key, MAPVK_VK_TO_VSC_EX);
		if (vsc == 0) return "";

		LONG lparam = (LONG) ((vsc & 0xff) << 16);
		if (vsc & 0xff00) lparam |= 1 << 24;// extended key

		wchar_t name[64] = {0};
		int len = GetKeyNameTextW(lparam, name, (int) (sizeof(name) / sizeof(*name)));
		if (len <= 0) return "";

		return String(name, (size_t) len);
	}

	static String
	make_item_string (const Menu* menu)
	{
		String str = menu->label();
		String key = menu->empty() ? get_shortcut_key_name(menu->shortcut_key()) : "";
		if (!key.empty())
		{
			str += '\t';
			uint mods = menu->shortcut_modifiers();
			if (mods &  MOD_CONTROL)           str += "Ctrl+";
			if (mods &  MOD_SHIFT)             str += "Shift+";
			if (mods & (MOD_ALT | MOD_OPTION)) str += "Alt+";
			str += key;
		}
		return str;
	}

	void
	Menu_update (Menu* menu)
	{
		MenuData& self = get_data(menu);

		if (!self.hparent) return;

		MENUITEMINFOW mii = {sizeof(mii)};
		mii.fMask         =
			MIIM_ID | MIIM_DATA | MIIM_FTYPE | MIIM_STATE | MIIM_BITMAP | MIIM_SUBMENU;
		mii.wID           = self.id;
		mii.dwItemData    = (ULONG_PTR) menu;

		std::wstring label;
		if (menu->is_separator())
			mii.fType = MFT_SEPARATOR;
		else
		{
			label = make_item_string(menu).to_wstr();

			mii.fMask     |= MIIM_STRING;
			mii.fType      = MFT_STRING;
			mii.dwTypeData = (LPWSTR) label.c_str();
			mii.fState     =
				(menu->is_enabled() ? MFS_ENABLED : MFS_GRAYED) |
				(menu->is_checked() ? MFS_CHECKED : MFS_UNCHECKED);
			mii.hbmpItem   = self.get_hbitmap(menu->image());
			mii.hSubMenu   = menu->empty() ? NULL : self.hsubmenu;
		}

		SetMenuItemInfoW(self.hparent, self.id, FALSE, &mii);

		set_modified(menu);
	}

	void
	Menu_popup (Menu* menu, View* view, coord x, coord y)
	{
		Menu_cancel_active_pointers_for_popup(view);

		MenuData& self = get_data(menu);

		HMENU hmenu = self.get_hsubmenu(menu, false);
		if (!hmenu)
			invalid_state_error(__FILE__, __LINE__);

		HWND hwnd = NULL;
		POINT pos = {(int) x, (int) y};

		if (view)
		{
			Window* win = view->window();
			if (!win)
				invalid_state_error(__FILE__, __LINE__);

			hwnd = Window_get_hwnd(win);
			if (!hwnd)
				invalid_state_error(__FILE__, __LINE__);

			Point p = view->to_window(Point(x, y));
			pos.x   = (int) p.x;
			pos.y   = (int) p.y;
			ClientToScreen(hwnd, &pos);
		}
		else
			hwnd = GetActiveWindow();

		if (!hwnd) return;

		// TrackPopupMenu needs the owner window in the foreground, and the
		// trailing WM_NULL is the documented workaround for the menu not closing
		// on the first outside click.
		SetForegroundWindow(hwnd);
		TrackPopupMenu(
			hmenu, TPM_LEFTALIGN | TPM_TOPALIGN | TPM_RIGHTBUTTON,
			pos.x, pos.y, 0, hwnd, NULL);
		PostMessageW(hwnd, WM_NULL, 0, 0);
	}

	void
	Menu_child_added (Menu* parent, Menu* child, int index)
	{
		MenuData& c = get_data(child);

		if (c.hparent)
			invalid_state_error(__FILE__, __LINE__);

		insert_item(get_data(parent).get_hsubmenu(parent), child, index);
	}

	void
	Menu_child_removed (Menu* parent, Menu* child)
	{
		MenuData& p = get_data(parent);
		MenuData& c = get_data(child);

		if (!p.hsubmenu)
			invalid_state_error(__FILE__, __LINE__);
		if (c.hparent != p.hsubmenu)
			invalid_state_error(__FILE__, __LINE__);

		RemoveMenu(p.hsubmenu, c.id, MF_BYCOMMAND);
		c.hparent = NULL;

		set_modified(parent);
	}

	HMENU
	Menu_get_hmenu (Menu* menu)
	{
		return menu ? get_data(menu).get_hsubmenu(menu, true) : NULL;
	}

	bool
	Menu_is_modified (Menu* menu)
	{
		return menu && get_data(menu).modified;
	}

	static void
	collect_accels (std::vector<ACCEL>* accels, Menu* menu)
	{
		for (auto& child : *menu)
		{
			Menu* item = child.get();
			if (!item) continue;

			int key = item->shortcut_key();
			if (key >= 0 && item->empty())
			{
				uint mods = item->shortcut_modifiers();

				ACCEL accel = {0};
				accel.key   = (WORD) key;// KeyCode == VK
				accel.cmd   = (WORD) get_data(item).id;
				accel.fVirt = (BYTE)              (FVIRTKEY      |
					(mods &  MOD_CONTROL           ? FCONTROL : 0) |
					(mods &  MOD_SHIFT             ? FSHIFT   : 0) |
					(mods & (MOD_ALT | MOD_OPTION) ? FALT     : 0));
				accels->emplace_back(accel);
			}

			collect_accels(accels, item);
		}
	}

	HACCEL
	Menu_create_accelerator_table (Menu* menu)
	{
		if (!menu) return NULL;

		get_data(menu).modified = false;

		std::vector<ACCEL> accels;
		collect_accels(&accels, menu);
		if (accels.empty()) return NULL;

		return CreateAcceleratorTableW(accels.data(), (int) accels.size());
	}

	static Menu*
	find_item (Menu* menu, UINT id)
	{
		for (auto& child : *menu)
		{
			Menu* item = child.get();
			if (!item || !item->is_enabled()) continue;

			if (get_data(item).id == id) return item;

			Menu* found = find_item(item, id);
			if (found) return found;
		}
		return NULL;
	}

	void
	Menu_call_command_event (Menu* menu, uint id)
	{
		if (!menu) return;

		Menu* item = find_item(menu, (UINT) id);
		if (!item) return;

		Event e;
		item->on_click(&e);
	}

	void
	Menu_call_command_event (HMENU hmenu, uint index)
	{
		Menu* menu = get_item_owner(hmenu, index);
		if (!menu) return;

		Event e;
		menu->on_click(&e);
	}

	void
	Menu_call_open_event (HMENU hmenu)
	{
		Menu* menu = get_submenu_owner(hmenu);
		if (!menu) return;

		Event e;
		menu->on_open_submenu(&e);

		int count = GetMenuItemCount(hmenu);
		for (int i = 0; i < count; ++i)
		{
			Menu* child = get_item_owner(hmenu, i);
			if (!child) continue;

			Event ce;
			child->on_show(&ce);
		}
	}

	void
	Menu_call_close_event (HMENU hmenu)
	{
		Menu* menu = get_submenu_owner(hmenu);
		if (!menu) return;

		int count = GetMenuItemCount(hmenu);
		for (int i = 0; i < count; ++i)
		{
			Menu* child = get_item_owner(hmenu, i);
			if (!child) continue;

			Event ce;
			child->on_hide(&ce);
		}

		Event e;
		menu->on_close_submenu(&e);
	}


	HMENU
	MenuData::get_hsubmenu (Menu* menu, bool menubar)
	{
		if (!hsubmenu)
		{
			hsubmenu      = create_hmenu(menu, menubar);
			this->menubar = menubar;
		}
		else if (menubar != this->menubar)
		{
			HMENU old     = hsubmenu;
			hsubmenu      = create_hmenu(menu, menubar);
			this->menubar = menubar;

			int index = 0;
			for (auto it = menu->begin(); it != menu->end(); ++it, ++index)
				insert_item(hsubmenu, it->get(), index);
			destroy_hmenu(old);
		}
		return hsubmenu;
	}


}// Reflex
