// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_WIN32_GDI_H__
#define __RAYS_SRC_WIN32_GDI_H__


#include <windows.h>
#include <xot/pimpl.h>
#include <rays/defs.h>


namespace Rays
{


	namespace Win32
	{


		class Pen
		{

			public:

				Pen (HPEN handle = NULL, bool owner = false);

				Pen (int red, int green, int blue, int width = 1, int style = PS_SOLID);

				~Pen ();

				bool get_color (int* red, int* green, int* blue) const;

				HPEN handle () const;

				operator bool () const;

				bool operator ! () const;

				struct Data;

				Xot::PSharedImpl<Data> self;

		};// Pen


		class Brush
		{

			public:

				Brush (HBRUSH handle = NULL, bool owner = false);

				Brush (int red, int green, int blue, int style = BS_SOLID);

				~Brush ();

				bool get_color (int* red, int* green, int* blue) const;

				HBRUSH handle () const;

				operator bool () const;

				bool operator ! () const;

				struct Data;

				Xot::PSharedImpl<Data> self;

		};// Brush


		class Font
		{

			public:

				Font (HFONT handle = NULL, bool owner = false);

				Font (const char* name, coord size = 0);

				~Font ();

				String name () const;

				coord size () const;

				bool get_extent (
					coord* width, coord* height, const char* str, HDC hdc = NULL);

				HFONT handle () const;

				operator bool () const;

				bool operator ! () const;

				struct Data;

				Xot::PSharedImpl<Data> self;

		};// Font


		class Bitmap
		{

			public:

				Bitmap (HBITMAP handle = NULL, bool owner = false);

				Bitmap (HDC hdc, int width, int height);

				~Bitmap ();

				int width () const;

				int height () const;

				HBITMAP handle () const;

				operator bool () const;

				bool operator ! () const;

				struct Data;

				Xot::PSharedImpl<Data> self;

		};// Bitmap


		class DC
		{

			public:

				enum DeleteType {DELETE_DC, RELEASE_DC};

				DC (
					HDC handle = NULL, bool owner = false,
					DeleteType deltype = DELETE_DC);

				~DC ();

				Pen      pen () const;

				bool set_pen (const Pen& pen);

				Brush    brush () const;

				bool set_brush (const Brush& brush);

				Font     font () const;

				bool set_font (const Font& font);

				Bitmap   bitmap () const;

				bool set_bitmap (const Bitmap& bitmap);

				COLORREF text_color () const;

				bool set_text_color (COLORREF color);

				COLORREF back_color () const;

				bool set_back_color (COLORREF color);

				int      back_mode () const;

				bool set_back_mode (int mode);

				bool push ();

				bool pop ();

				HDC handle () const;

				operator bool () const;

				bool operator ! () const;

				struct Data;

				Xot::PSharedImpl<Data> self;

		};// DC


		class MemoryDC : public DC
		{

			typedef DC Super;

			public:

				MemoryDC ();

				MemoryDC (HDC hdc, int width, int height);

				MemoryDC (HDC hdc, const Bitmap& bitmap);

				~MemoryDC ();

				const Bitmap& bitmap () const;

				operator bool () const;

				bool operator ! () const;

				struct Data;

				Xot::PSharedImpl<Data> self;

		};// MemoryDC


		DC screen_dc ();


	}// Win32


}// Rays


#endif//EOH
