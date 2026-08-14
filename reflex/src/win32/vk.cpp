// vk.h needs VK_NAVIGATION_*, but winuser.h defines them only when
// _WIN32_WINNT >= 0x0604, and RbConfig's CPPFLAGS sets it to 0x0600.
// so set a higher value here before vk.h includes windows.h.
#if _WIN32_WINNT >= 0x0604
	#error _WIN32_WINNT is now high enough; delete this workaround
#endif

#undef  _WIN32_WINNT
#define _WIN32_WINNT 0x0A00

#include "../vk.h"
