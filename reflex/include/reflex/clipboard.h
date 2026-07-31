// -*- c++ -*-
#pragma once
#ifndef __REFLEX_CLIPBOARD_H__
#define __REFLEX_CLIPBOARD_H__


#include <xot/pimpl.h>
#include <reflex/defs.h>


namespace Reflex
{


	class Clipboard
	{

		public:

			Clipboard (const char* text = NULL);

			~Clipboard ();

			void    set_text (const char* text);

			const char* text () const;

			void     set_image (const Image& image);

			const Image* image () const;

			void clear ();

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Clipboard


	void      set_clipboard (const Clipboard& clipboard);

	Clipboard get_clipboard ();


}// Reflex


#endif//EOH
