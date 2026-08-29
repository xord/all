// -*- c++ -*-
#pragma once
#ifndef __REFLEX_FILE_DIALOG_H__
#define __REFLEX_FILE_DIALOG_H__


#include <xot/ref.h>
#include <xot/pimpl.h>
#include <reflex/defs.h>
#include <reflex/event.h>


namespace Reflex
{


	class Window;


	class FileDialog : public Xot::RefCountable<>
	{

		typedef FileDialog This;

		public:

			typedef Xot::Ref<This> Ref;

			FileDialog ();

			virtual ~FileDialog ();

			virtual void open_file      (const char* dir = NULL);

			virtual void open_files     (const char* dir = NULL);

			virtual void open_directory (const char* dir = NULL);

			virtual void save_file      (const char* dir = NULL, const char* name = NULL);

			virtual void      set_owner (Window* window);

			virtual       Window* owner ();

			virtual const Window* owner () const;

			virtual void    set_title (const char* title);

			virtual const char* title () const;

			virtual void          set_extensions (const StringList& extensions);

			virtual const StringList& extensions () const;

			virtual void on_file (FileEvent* e);

			virtual void on_cancel (Event* e);

			virtual operator bool () const;

			virtual bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// FileDialog


}// Reflex


#endif//EOH
