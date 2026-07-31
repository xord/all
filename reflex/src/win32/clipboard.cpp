#include "reflex/clipboard.h"


#include <string.h>
#include <wchar.h>
#include <xot/noncopyable.h>
#include <xot/windows.h>
#include "reflex/exception.h"


namespace Reflex
{


	class ClipboardLock : public Xot::NonCopyable
	{

		enum
		{

			RETRY_COUNT = 3,

			RETRY_INTERVAL = 30// milliseconds

		};

		public:

			ClipboardLock ()
			:	opened(false)
			{
				// OpenClipboard fails while another process has the clipboard open
				for (int i = 0; i < RETRY_COUNT; ++i)
				{
					if (i > 0) Sleep(RETRY_INTERVAL);

					opened = OpenClipboard(NULL) != FALSE;
					if (opened) break;
				}
			}

			~ClipboardLock ()
			{
				if (opened) CloseClipboard();
			}

			operator bool () const
			{
				return opened;
			}

		private:

			bool opened;

	};// ClipboardLock


	class GlobalMemory : public Xot::NonCopyable
	{

		public:

			GlobalMemory (HGLOBAL handle, bool owner = false)
			:	handle(handle), owner(owner), pointer(NULL)
			{
			}

			~GlobalMemory ()
			{
				unlock();
				if (handle && owner) GlobalFree(handle);
			}

			void* lock ()
			{
				if (!pointer && handle) pointer = GlobalLock(handle);
				return pointer;
			}

			void unlock ()
			{
				if (!pointer) return;
				GlobalUnlock(handle);
				pointer = NULL;
			}

			HGLOBAL release ()
			{
				owner = false;
				return handle;
			}

			HGLOBAL get () const
			{
				return handle;
			}

			operator bool () const
			{
				return handle != NULL;
			}

		private:

			HGLOBAL handle;

			bool owner;

			void* pointer;

	};// GlobalMemory


	static String
	to_crlf (const char* text)
	{
		String result;
		for (const char* p = text; *p; ++p)
		{
			if (*p == '\r' || *p == '\n')
			{
				result += "\r\n";
				if (*p == '\r' && *(p + 1) == '\n') ++p;
				continue;
			}
			result += *p;
		}
		return result;
	}

	static String
	to_lf (const String& text)
	{
		size_t size = text.size();
		String result;
		result.reserve(size);
		for (size_t i = 0; i < size; ++i)
		{
			char c = text[i];
			if (c == '\r')
			{
				if ((i + 1) < size && text[i + 1] == '\n') continue;
				c = '\n';
			}
			result += c;
		}
		return result;
	}

	static HGLOBAL
	create_text_handle (const char* text)
	{
		std::wstring wtext = to_crlf(text).to_wstr();
		size_t size        = (wtext.size() + 1) * sizeof(wchar_t);

		GlobalMemory mem(GlobalAlloc(GMEM_MOVEABLE, size), true);
		if (!mem)
			system_error(__FILE__, __LINE__);

		void* buffer = mem.lock();
		if (!buffer)
			system_error(__FILE__, __LINE__);

		memcpy(buffer, wtext.c_str(), size);
		mem.unlock();

		return mem.release();
	}

	void
	set_clipboard (const Clipboard& clipboard)
	{
		const char* text = clipboard.text();
		GlobalMemory textmem(text ? create_text_handle(text) : NULL, true);

		ClipboardLock lock;
		if (!lock)
			system_error(__FILE__, __LINE__);

		if (!EmptyClipboard())
			system_error(__FILE__, __LINE__);

		if (textmem)
		{
			if (!SetClipboardData(CF_UNICODETEXT, textmem.get()))
				system_error(__FILE__, __LINE__);
			textmem.release();
		}
	}

	Clipboard
	get_clipboard ()
	{
		ClipboardLock lock;
		if (!lock)
			system_error(__FILE__, __LINE__);

		Clipboard clipboard;

		GlobalMemory textmem(GetClipboardData(CF_UNICODETEXT));
		const wchar_t* text = (const wchar_t*) textmem.lock();
		if (text)
			clipboard.set_text(to_lf(String(text, wcslen(text))).c_str());

		return clipboard;
	}


}// Reflex
