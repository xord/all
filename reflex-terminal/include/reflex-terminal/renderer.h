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


	// Draws a terminal's screen.
	//
	// Every glyph is rasterized once into an atlas and drawn from there
	// as an image copy, since Painter::text() flushes the batch and
	// uploads a texture on every call. Stepping the cells from Ruby cost
	// more in crossing into the drawing library than the drawing did.
	//
	// The cursor is left to the caller. A terminal says where it is and
	// what shape it asked for, but a bar, a block or nothing at all is
	// the application's decision.
	//
	class Renderer
	{

		public:

			Renderer ();

			Renderer (const Font& font);

			~Renderer ();

			// throws the atlas away and measures the cell again
			void    set_font (const Font& font);

			const Font& font () const;

			// the cell the font measures out, which is what the terminal
			// is sized in
			coord cell_width () const;

			coord cell_height () const;

			// rasterizes every glyph on the screen the atlas has not seen
			// before, seeding an empty one with printable ascii as it
			// goes. this paints into an offscreen image, which switches
			// the rendering context and replaces the image whenever it
			// grows, so it must not run inside a frame being drawn
			void bake_glyphs (const Reflex::Terminal& terminal);

			// how many glyphs the atlas has been asked to hold, whether
			// or not it had the room for them
			size_t glyph_count () const;

			void draw (
				Painter* painter, const Reflex::Terminal& terminal,
				const Bounds& bounds);

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Renderer


}// ReflexTerminal


#endif//EOH
