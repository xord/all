#include "tray.h"


#include <vector>
#include <xot/windows.h>
#include <shellapi.h>
#include "reflex/exception.h"
#include "../rays.h"
#include "application.h"
#include "menu.h"


namespace Reflex
{


	enum {TRAY_ICON_ID = 1, WM_TRAY_ICON = WM_APP + 1};

	static HWND tray_hwnd  = NULL;

	static Menu* tray_menu = NULL;

	static HICON tray_icon = NULL;

	static bool tray_shown = false;


	static void
	popup_tray_menu ()
	{
		if (!tray_hwnd || !tray_menu) return;

		POINT pos;
		if (!GetCursorPos(&pos)) return;

		// TrackPopupMenu needs the owner window in the foreground, and the
		// trailing WM_NULL is the documented workaround for the menu not closing
		// on the first outside click.
		SetForegroundWindow(tray_hwnd);
		TrackPopupMenu(
			Menu_get_hmenu(tray_menu),
			TPM_LEFTALIGN | TPM_BOTTOMALIGN | TPM_RIGHTBUTTON,
			pos.x, pos.y, 0, tray_hwnd, NULL);
		PostMessageW(tray_hwnd, WM_NULL, 0, 0);
	}

	static LRESULT CALLBACK
	tray_wndproc (HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
	{
		return Application_guard([&]() -> LRESULT
		{
			switch (msg)
			{
				case WM_TRAY_ICON:
				{
					if (lp == WM_LBUTTONUP || lp == WM_RBUTTONUP)
						popup_tray_menu();
					return 0;
				}

				case WM_MENUCOMMAND:
				{
					Menu_call_command_event((HMENU) lp, (uint) wp);
					return 0;
				}

				case WM_INITMENUPOPUP:
				{
					Menu_call_open_event((HMENU) wp);
					break;
				}

				case WM_UNINITMENUPOPUP:
				{
					Menu_call_close_event((HMENU) wp);
					break;
				}
			}
			return DefWindowProcW(hwnd, msg, wp, lp);
		}, (LRESULT) 0);
	}

	static HWND
	create_tray_window ()
	{
		static const wchar_t* WINDOWCLASS = L"Reflex:TrayWindowClass";

		WNDCLASSEXW wc   = {sizeof(wc)};
		wc.lpfnWndProc   = tray_wndproc;
		wc.hInstance     = GetModuleHandle(NULL);
		wc.lpszClassName = WINDOWCLASS;
		if (!RegisterClassExW(&wc))
			system_error(__FILE__, __LINE__);

		HWND hwnd = CreateWindowExW(
			WS_EX_TOOLWINDOW, WINDOWCLASS, L"", WS_POPUP,
			0, 0, 0, 0, NULL, NULL, wc.hInstance, NULL);
		if (!hwnd)
			system_error(__FILE__, __LINE__);

		return hwnd;
	}

	static HICON
	create_tray_icon (const Image& image)
	{
		HBITMAP color = Rays::Bitmap_get_hbitmap(image.bitmap());
		if (!color) return NULL;

		BITMAP bmp = {0};
		GetObjectW(color, sizeof(bmp), &bmp);

		// the mask is required but the alpha channel decides what shows,
		// so it stays all zero
		int stride = ((bmp.bmWidth + 15) / 16) * 2;
		std::vector<BYTE> zero((size_t) stride * bmp.bmHeight, 0);
		HBITMAP mask = CreateBitmap(bmp.bmWidth, bmp.bmHeight, 1, 1, zero.data());

		ICONINFO info = {0};
		info.fIcon    = TRUE;
		info.hbmColor = color;
		info.hbmMask  = mask;

		HICON icon = CreateIconIndirect(&info);
		DeleteObject(mask);
		DeleteObject(color);
		return icon;
	}

	void
	Tray_update_icon (Application* app)
	{
		Menu* menu = app ? app->background_menu() : NULL;
		if (!menu && app && app->background())
			menu = app->menu();

		if (!menu)
		{
			Tray_remove_icon();
			Application_quit_if_should();
			return;
		}

		if (!tray_hwnd)
			tray_hwnd = create_tray_window();

		if (tray_icon)
		{
			DestroyIcon(tray_icon);
			tray_icon = NULL;
		}
		if (menu->image())
			tray_icon = create_tray_icon(menu->image());

		String tip           = menu->label();
		if (tip.empty()) tip = app->name();

		NOTIFYICONDATAW nid  = {sizeof(nid)};
		nid.hWnd             = tray_hwnd;
		nid.uID              = TRAY_ICON_ID;
		nid.uFlags           = NIF_MESSAGE | NIF_ICON | NIF_TIP;
		nid.uCallbackMessage = WM_TRAY_ICON;
		nid.hIcon            =
			tray_icon ? tray_icon : LoadIconW(NULL, (LPCWSTR) IDI_APPLICATION);
		lstrcpynW(nid.szTip, tip.to_wstr().c_str(), sizeof(nid.szTip) / sizeof(*nid.szTip));

		Shell_NotifyIconW(tray_shown ? NIM_MODIFY : NIM_ADD, &nid);
		tray_shown = true;
		tray_menu  = menu;
	}

	void
	Tray_remove_icon ()
	{
		if (tray_shown)
		{
			NOTIFYICONDATAW nid = {sizeof(nid)};
			nid.hWnd            = tray_hwnd;
			nid.uID             = TRAY_ICON_ID;
			Shell_NotifyIconW(NIM_DELETE, &nid);
			tray_shown = false;
		}

		if (tray_icon)
		{
			DestroyIcon(tray_icon);
			tray_icon = NULL;
		}

		tray_menu = NULL;
	}


}// Reflex
