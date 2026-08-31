// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_FILE_DIALOG_H__
#define __REFLEX_SRC_FILE_DIALOG_H__


#include "reflex/file_dialog.h"
#include "reflex/window.h"


namespace Reflex
{


	struct FileDialog::Data
	{

		enum Mode
		{

			OPEN_FILE = 0,

			OPEN_FILES,

			OPEN_DIRECTORY,

			SAVE_FILE

		};// Mode

		Xot::WeakRef<Window> owner;

		String title;

		StringList extensions;

	};// FileDialog::Data


	void FileDialog_show (
		FileDialog* dialog, FileDialog::Data::Mode mode,
		const char* dir, const char* name);

	void FileDialog_call_file_event   (FileDialog* dialog, FileEvent* event);

	void FileDialog_call_cancel_event (FileDialog* dialog, Event* event);


}// Reflex


#endif//EOH
