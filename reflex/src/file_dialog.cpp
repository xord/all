#include "file_dialog.h"


#include "reflex/exception.h"
#include "window.h"


namespace Reflex
{


	void
	FileDialog_call_file_event (FileDialog* dialog, FileEvent* event)
	{
		if (!dialog)
			argument_error(__FILE__, __LINE__);
		if (!event)
			argument_error(__FILE__, __LINE__);

		dialog->on_file(event);
		if (event->is_blocked()) return;

		if (dialog->owner())
			Window_call_file_event(dialog->owner(), event);
	}

	void
	FileDialog_call_cancel_event (FileDialog* dialog, Event* event)
	{
		if (!dialog)
			argument_error(__FILE__, __LINE__);
		if (!event)
			argument_error(__FILE__, __LINE__);

		dialog->on_cancel(event);
	}


	FileDialog::FileDialog ()
	{
	}

	FileDialog::~FileDialog ()
	{
	}

	void
	FileDialog::open_file (const char* dir)
	{
		FileDialog_show(this, Data::OPEN_FILE, dir, NULL);
	}

	void
	FileDialog::open_files (const char* dir)
	{
		FileDialog_show(this, Data::OPEN_FILES, dir, NULL);
	}

	void
	FileDialog::open_directory (const char* dir)
	{
		FileDialog_show(this, Data::OPEN_DIRECTORY, dir, NULL);
	}

	void
	FileDialog::save_file (const char* dir, const char* name)
	{
		FileDialog_show(this, Data::SAVE_FILE, dir, name);
	}

	void
	FileDialog::set_owner (Window* window)
	{
		self->owner = window;
	}

	Window*
	FileDialog::owner ()
	{
		return self->owner;
	}

	const Window*
	FileDialog::owner () const
	{
		return const_cast<FileDialog*>(this)->owner();
	}

	void
	FileDialog::set_title (const char* title)
	{
		if (!title)
			argument_error(__FILE__, __LINE__);

		self->title = title;
	}

	const char*
	FileDialog::title () const
	{
		return self->title;
	}

	static String
	to_extension (const String& extension)
	{
		size_t start = extension.find_first_not_of('.');
		if (start == String::npos)
			argument_error(__FILE__, __LINE__);

		String result = extension.substr(start);
		if (result.find_first_of("*?[]/\\;") != String::npos)
			argument_error(__FILE__, __LINE__);

		return result;
	}

	void
	FileDialog::set_extensions (const StringList& extensions)
	{
		StringList list;
		for (const auto& extension : extensions)
			list.emplace_back(to_extension(extension));

		self->extensions = list;
	}

	const StringList&
	FileDialog::extensions () const
	{
		return self->extensions;
	}

	void
	FileDialog::on_file (FileEvent* e)
	{
	}

	void
	FileDialog::on_cancel (Event* e)
	{
	}

	FileDialog::operator bool () const
	{
		return true;
	}

	bool
	FileDialog::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
