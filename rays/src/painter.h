// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_PAINTER_H__
#define __RAYS_SRC_PAINTER_H__


#include <vector>
#include "rays/painter.h"
#include "rays/bounds.h"
#include "rays/color.h"
#include "rays/font.h"
#include "rays/image.h"
#include "rays/shader.h"
#include "matrix.h"
#include "texture.h"


namespace Rays
{


	enum ColorType
	{

		FILL = 0,

		STROKE,

		COLOR_TYPE_MAX

	};// ColorType


	enum PrimitiveMode
	{

		MODE_NONE           = -1,

		MODE_POINTS         = 0x0,

		MODE_LINES          = 0x1,

		MODE_LINE_LOOP      = 0x2,

		MODE_LINE_STRIP     = 0x3,

		MODE_TRIANGLES      = 0x4,

		MODE_TRIANGLE_STRIP = 0x5,

		MODE_TRIANGLE_FAN   = 0x6,

		MODE_QUADS          = 0x7,

		MODE_QUAD_STRIP     = 0x8,

		MODE_POLYGON        = 0x9,

	};// PrimitiveMode


	struct State
	{

		Color background, colors[COLOR_TYPE_MAX];

		bool nocolors[COLOR_TYPE_MAX];

		coord stroke_width;

		float stroke_outset;

		CapType stroke_cap;

		JoinType stroke_join;

		coord miter_limit;

		uint nsegment;

		coord line_height;

		BlendMode blend_mode;

		Bounds clip;

		Font font;

		Image texture;

		TexCoordMode texcoord_mode;

		TexCoordWrap texcoord_wrap;

		Shader shader;

		void init ()
		{
			background       .reset(0, 0);
			  colors[FILL]   .reset(1, 1);
			  colors[STROKE] .reset(1, 0);
			nocolors[FILL]   = false;
			nocolors[STROKE] = true;
			stroke_width     = 0;
			stroke_outset    = 0;
			stroke_cap       = CAP_DEFAULT;
			stroke_join      = JOIN_DEFAULT;
			miter_limit      = JOIN_DEFAULT_MITER_LIMIT;
			nsegment         = 0;
			line_height      = -1;
			blend_mode       = BLEND_NORMAL;
			clip             .reset(-1);
			font             = get_default_font();
			texture          = Image();
			texcoord_mode    = TEXCOORD_IMAGE;
			texcoord_wrap    = TEXCOORD_CLAMP;
			shader           = Shader();
		}

		bool get_color (Color* color, ColorType type) const
		{
			const Color& c = colors[type];
			if (blend_mode == BLEND_REPLACE ? nocolors[type] : !c)
				return false;

			*color = c;
			return true;
		}

		bool has_color () const
		{
			if (blend_mode == BLEND_REPLACE)
				return !nocolors[FILL] || !nocolors[STROKE];
			else
				return colors[FILL] || colors[STROKE];
		}

	};// State


	struct TextureInfo
	{

		const Texture& texture;

		Point min, max;

		TextureInfo (
			const Texture& texture,
			coord x_min, coord y_min,
			coord x_max, coord y_max)
		:	texture(texture)
		{
			min.reset(x_min, y_min);
			max.reset(x_max, y_max);
		}

		operator bool () const
		{
			return
				texture &&
				min.x < max.x &&
				min.y < max.y;
		}

		bool operator ! () const
		{
			return !operator bool();
		}

	};// TextureInfo


	struct Painter::Data
	{

		bool painting       = false;

		float pixel_density = 1;

		Bounds viewport;

		State              state;

		std::vector<State> state_stack;

		Matrix              position_matrix;

		std::vector<Matrix> position_matrix_stack;

		Image text_image;

		Data ()
		{
			state.init();
		}

		virtual ~Data () = default;

		void set_pixel_density (float density);

	};// Painter::Data


	void Painter_update_clip (Painter* painter);

	void Painter_draw (
		Painter* painter, PrimitiveMode mode, const Color* color,
		const Coord3* points,              size_t npoints,
		const uint*   indices      = NULL, size_t nindices = 0,
		const Color*  colors       = NULL,
		const Coord3* texcoords    = NULL,
		const TextureInfo* texinfo = NULL,
		const Shader* shader       = NULL);

	void Painter_draw_image (
		Painter* painter, const Image& image,
		coord src_x, coord src_y, coord src_w, coord src_h,
		coord dst_x, coord dst_y, coord dst_w, coord dst_h,
		bool nofill = false, bool nostroke = false,
		const Shader* shader = NULL);

	void Painter_draw_text_line (
		Painter* painter, const Font& font, const char* line, coord x, coord y,
		coord width = 0, coord height = 0);


}// Rays


#endif//EOH
