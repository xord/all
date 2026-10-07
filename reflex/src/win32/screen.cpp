#include "screen.h"


#include <wchar.h>
#include <algorithm>
#include <vector>
#include "reflex/exception.h"


namespace Reflex
{


	struct Screen::Data
	{

		HMONITOR handle = NULL;

	};// Screen::Data


	void
	Screen_initialize (Screen* pthis, HMONITOR hmonitor)
	{
		pthis->self->handle = hmonitor;
	}


	Screen::Screen ()
	{
	}

	Screen::~Screen ()
	{
	}

	static String
	get_monitor_name (const wchar_t* device)
	{
		UINT32 npaths = 0, nmodes = 0;
		if (GetDisplayConfigBufferSizes(QDC_ONLY_ACTIVE_PATHS, &npaths, &nmodes) != ERROR_SUCCESS)
			return "";

		std::vector<DISPLAYCONFIG_PATH_INFO> paths(npaths);
		std::vector<DISPLAYCONFIG_MODE_INFO> modes(nmodes);
		LONG ret = QueryDisplayConfig(
			QDC_ONLY_ACTIVE_PATHS, &npaths, paths.data(), &nmodes, modes.data(), NULL);
		if (ret != ERROR_SUCCESS)
			return "";

		for (UINT32 i = 0; i < npaths; ++i)
		{
			const auto& path = paths[i];

			DISPLAYCONFIG_SOURCE_DEVICE_NAME source = {};
			source.header.type      = DISPLAYCONFIG_DEVICE_INFO_GET_SOURCE_NAME;
			source.header.size      = sizeof(source);
			source.header.adapterId = path.sourceInfo.adapterId;
			source.header.id        = path.sourceInfo.id;
			if (
				DisplayConfigGetDeviceInfo(&source.header) != ERROR_SUCCESS ||
				wcscmp(source.viewGdiDeviceName, device)   != 0)
			{
				continue;
			}

			DISPLAYCONFIG_TARGET_DEVICE_NAME target = {};
			target.header.type      = DISPLAYCONFIG_DEVICE_INFO_GET_TARGET_NAME;
			target.header.size      = sizeof(target);
			target.header.adapterId = path.targetInfo.adapterId;
			target.header.id        = path.targetInfo.id;
			if (DisplayConfigGetDeviceInfo(&target.header) != ERROR_SUCCESS)
				continue;

			const wchar_t* name = target.monitorFriendlyDeviceName;
			if (*name)
				return String(name, wcslen(name));
		}
		return "";
	}

	String
	Screen::name () const
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		MONITORINFOEXW mi = {};
		mi.cbSize         = sizeof(mi);
		if (!GetMonitorInfoW(self->handle, &mi))
			system_error(__FILE__, __LINE__);

		String name = get_monitor_name(mi.szDevice);
		if (name.empty())
		{
			const wchar_t* device = mi.szDevice;
			if (wcsncmp(device, L"\\\\.\\", 4) == 0) device += 4;
			name = String(device, wcslen(device));
		}

		return name;
	}

	Bounds
	Screen::frame () const
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		MONITORINFO mi = {0};
		mi.cbSize      = sizeof(mi);
		if (!GetMonitorInfoW(self->handle, &mi))
			system_error(__FILE__, __LINE__);

		const auto& r = mi.rcMonitor;
		return Bounds(r.left, r.top, r.right - r.left, r.bottom - r.top);
	}

	float
	Screen::pixel_density () const
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		return 1;
	}

	Screen::operator bool () const
	{
		return self->handle;
	}

	bool
	Screen::operator ! () const
	{
		return !operator bool();
	}

	static BOOL CALLBACK
	add_screen (HMONITOR hmonitor, HDC, LPRECT, LPARAM lp)
	{
		Screen s;
		Screen_initialize(&s, hmonitor);
		((Screen::List*) lp)->emplace_back(s);
		return TRUE;
	}

	static bool
	is_primary (const Screen& screen)
	{
		MONITORINFO mi = {0};
		mi.cbSize      = sizeof(mi);
		if (!GetMonitorInfoW(screen.self->handle, &mi))
			return false;

		return mi.dwFlags & MONITORINFOF_PRIMARY;
	}

	Screen::List
	Screen::all ()
	{
		List list;
		if (!EnumDisplayMonitors(NULL, NULL, add_screen, (LPARAM) &list))
			system_error(__FILE__, __LINE__);

		std::stable_partition(list.begin(), list.end(), is_primary);
		return list;
	}


}// Reflex
