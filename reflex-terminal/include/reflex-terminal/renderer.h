// -*- c++ -*-
#pragma once
#ifndef __REFLEX_TERMINAL_RENDERER_H__
#define __REFLEX_TERMINAL_RENDERER_H__


#include <xot/pimpl.h>
#include <rays/bounds.h>
#include <rays/color.h>
#include <rays/font.h>
#include <rays/painter.h>
#include <reflex-terminal/defs.h>
#include <reflex/terminal.h>


namespace ReflexTerminal
{


	class Renderer
	{

		public:

			Renderer ();

			Renderer (const Font& font);

			~Renderer ();

			void    set_font (const Font& font);

			const Font& font () const;

			coord cell_width () const;

			coord cell_height () const;

			void bake_glyphs (const Reflex::Terminal& terminal);

			size_t    glyph_count () const;

			void set_blink_visible (bool visible);

			bool     blink_visible () const;

			void set_background_alpha (float alpha);

			float    background_alpha () const;

			void draw (
				Painter* painter, const Reflex::Terminal& terminal,
				const Bounds& bounds);

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Renderer


}// ReflexTerminal


#endif//EOH
