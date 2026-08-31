#include "../file_dialog.h"


#include <wchar.h>
#include <string>
#include <xot/windows.h>
#include <shobjidl.h>
#include <xot/noncopyable.h>
#include "reflex/exception.h"
#include "window.h"


namespace Reflex
{


	template <typename T>
	struct ComPtr : public Xot::NonCopyable
	{

		T* ptr = NULL;

		~ComPtr () {if (ptr) ptr->Release();}

		T* operator -> () {return ptr;}

		operator bool () const {return ptr != NULL;}

	};// ComPtr


	static std::wstring
	to_native_path (const char* path)
	{
		std::wstring result = String(path).to_wstr();
		for (auto& c : result)
		{
			if (c == L'/') c = L'\\';
		}
		return result;
	}

	static String
	from_native_path (PCWSTR path, size_t size)
	{
		String result(path, size);
		for (auto& c : result)
		{
			if (c == '\\') c = '/';
		}
		return result;
	}

	static void
	setup_options (IFileDialog* nativedialog, FileDialog::Data::Mode mode)
	{
		FILEOPENDIALOGOPTIONS options = 0;
		if (FAILED(nativedialog->GetOptions(&options)))
			system_error(__FILE__, __LINE__);

		options |= FOS_FORCEFILESYSTEM;
		if (mode == FileDialog::Data::OPEN_DIRECTORY) options |= FOS_PICKFOLDERS;
		if (mode == FileDialog::Data::OPEN_FILES)     options |= FOS_ALLOWMULTISELECT;

		if (FAILED(nativedialog->SetOptions(options)))
			system_error(__FILE__, __LINE__);
	}

	static void
	setup_file_types (
		std::wstring* joined,
		IFileDialog* nativedialog, const FileDialog* dialog, FileDialog::Data::Mode mode)
	{
		if (mode == FileDialog::Data::OPEN_DIRECTORY)
			return;

		const StringList& extensions = dialog->extensions();
		if (extensions.empty())
			return;

		for (const auto& extension : extensions)
		{
			if (!joined->empty()) *joined += L';';
			*joined += ("*." + extension).to_wstr();
		}

		COMDLG_FILTERSPEC spec = {L"Files", joined->c_str()};
		nativedialog->SetFileTypes(1, &spec);
	}

	static void
	add_path (StringList* paths, IShellItem* item)
	{
		PWSTR wpath = NULL;
		if (FAILED(item->GetDisplayName(SIGDN_FILESYSPATH, &wpath)) || !wpath)
			return;

		paths->emplace_back(from_native_path(wpath, wcslen(wpath)));
		CoTaskMemFree(wpath);
	}

	static bool
	is_missing_result (HRESULT hresult)
	{
		// closing the last window ends the modal loop of Show() with a WM_QUIT,
		// and it answers S_OK though nothing was ever chosen. asking for the
		// result then gives E_FAIL, which is this dialog being over, not an error
		return hresult == E_FAIL;
	}

	static void
	get_open_paths (StringList* paths, IFileOpenDialog* nativedialog)
	{
		ComPtr<IShellItemArray> items;
		HRESULT result = nativedialog->GetResults(&items.ptr);
		if (is_missing_result(result))
			return;
		if (FAILED(result) || !items)
			system_error(__FILE__, __LINE__);

		DWORD count = 0;
		if (FAILED(items->GetCount(&count)))
			system_error(__FILE__, __LINE__);

		for (DWORD i = 0; i < count; ++i)
		{
			ComPtr<IShellItem> item;
			if (FAILED(items->GetItemAt(i, &item.ptr)) || !item)
				continue;

			add_path(paths, item.ptr);
		}
	}

	static void
	get_save_path (StringList* paths, IFileDialog* nativedialog)
	{
		ComPtr<IShellItem> item;
		HRESULT result = nativedialog->GetResult(&item.ptr);
		if (is_missing_result(result))
			return;
		if (FAILED(result) || !item)
			system_error(__FILE__, __LINE__);

		add_path(paths, item.ptr);
	}

	static void
	set_folder (IFileDialog* nativedialog, const char* dir)
	{
		// SetFolder overrides the folder the user last visited, so it is only
		// called when a directory was explicitly given
		ComPtr<IShellItem> item;
		HRESULT result = SHCreateItemFromParsingName(
			to_native_path(dir).c_str(), NULL, IID_IShellItem, (void**) &item.ptr);
		if (SUCCEEDED(result) && item)
			nativedialog->SetFolder(item.ptr);
	}

	void
	FileDialog_show (
		FileDialog* pdialog, FileDialog::Data::Mode mode,
		const char* dir, const char* name)
	{
		if (!pdialog)
			argument_error(__FILE__, __LINE__);

		FileDialog::Ref dialog = pdialog;
		bool save              = mode == FileDialog::Data::SAVE_FILE;

		ComPtr<IFileOpenDialog> opendialog;
		ComPtr<IFileDialog>     savedialog;
		HRESULT result = CoCreateInstance(
			save ? CLSID_FileSaveDialog     : CLSID_FileOpenDialog,
			NULL,
			CLSCTX_INPROC_SERVER,
			save ? IID_IFileDialog          : IID_IFileOpenDialog,
			save ? (void**) &savedialog.ptr : (void**) &opendialog.ptr);
		if (FAILED(result))
			system_error(__FILE__, __LINE__);

		IFileDialog* nativedialog = save ? savedialog.ptr : (IFileDialog*) opendialog.ptr;
		setup_options(nativedialog, mode);

		std::wstring joined;// keeps the filter string alive until Show()
		setup_file_types(&joined, nativedialog, dialog, mode);

		const char* title = dialog->title();
		if (*title)
			nativedialog->SetTitle(String(title).to_wstr().c_str());

		if (dir && *dir)
			set_folder(nativedialog, dir);

		if (save && name && *name)
			nativedialog->SetFileName(String(name).to_wstr().c_str());

		Window* owner = dialog->owner();
		HWND hwnd     = owner ? Window_get_hwnd(owner) : NULL;
		result        = nativedialog->Show(hwnd);// runs a modal loop

		StringList paths;
		if (SUCCEEDED(result))
		{
			if (save)
				get_save_path(&paths, savedialog.ptr);
			else
				get_open_paths(&paths, opendialog.ptr);
		}

		if (!paths.empty())
		{
			FileEvent e(save ? FileEvent::SAVE : FileEvent::OPEN, paths);
			FileDialog_call_file_event(dialog, &e);
		}
		else if (SUCCEEDED(result) || result == HRESULT_FROM_WIN32(ERROR_CANCELLED))
		{
			Event e;
			FileDialog_call_cancel_event(dialog, &e);
		}
		else
			system_error(__FILE__, __LINE__);
	}


}// Reflex
