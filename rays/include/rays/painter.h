// -*- c++ -*-
#pragma once
#ifndef __RAYS_PAINTER_H__
#define __RAYS_PAINTER_H__


#include <xot/pimpl.h>
#include <rays/defs.h>
#include <rays/point.h>


namespace Rays
{


	struct Bounds;
	struct Color;
	struct Matrix;

	class Polyline;
	class Polygon;
	class Image;
	class Font;
	class Shader;


	class Painter
	{

		public:

			Painter ();

			~Painter ();

			void canvas (
				coord x, coord y, coord width, coord height,
				float pixel_density = 1);

			void canvas (
				coord x, coord y, coord z, coord width, coord height, coord depth,
				float pixel_density = 1);

			void canvas (
				const Bounds& bounds,
				float pixel_density = 1);

			void bind (const Image& image);

			void unbind ();

			const Bounds& bounds () const;

			float pixel_density () const;


			//
			// drawing methods
			//
			void begin ();

			void end ();

			bool painting () const;

			void clear ();

			void polygon (
				const Polygon& polygon, coord x = 0, coord y = 0);

			void polygon (
				const Polygon& polygon, const Point& position);

			void polygon (
				const Polygon& polygon, coord x, coord y, coord width, coord height);

			void polygon (
				const Polygon& polygon, const Bounds& bounds);

			void line (coord x1, coord y1, coord x2, coord y2);

			void line (const Point& p1, const Point& p2);

			void line (const Point* points, size_t size, bool loop = false);

			void line (const Polyline& polyline);

			void rect (
				coord x, coord y, coord width, coord height,
				coord round = 0);

			void rect (
				coord x, coord y, coord width, coord height,
				coord round_left_top,    coord round_right_top,
				coord round_left_bottom, coord round_right_bottom);

			void rect (
				const Bounds& bounds,
				coord round = 0);

			void rect (
				const Bounds& bounds,
				coord round_left_top,    coord round_right_top,
				coord round_left_bottom, coord round_right_bottom);

			void ellipse (
				coord x, coord y, coord width, coord height = 0,
				const Point& hole_size = 0,
				float angle_from = 0, float angle_to = 360);

			void ellipse (
				const Bounds& bounds,
				const Point& hole_size = 0,
				float angle_from = 0, float angle_to = 360);

			void ellipse (
				const Point& center, const Point& radius,
				const Point& hole_radius = 0,
				float angle_from = 0, float angle_to = 360);

			void curve (
				coord x1, coord y1, coord x2, coord y2,
				coord x3, coord y3, coord x4, coord y4,
				bool loop = false);

			void curve (
				const Point& p1, const Point& p2, const Point& p3, const Point& p4,
				bool loop = false);

			void curve (
				const Point* points, size_t size,
				bool loop = false);

			void bezier (
				coord x1, coord y1, coord x2, coord y2,
				coord x3, coord y3, coord x4, coord y4,
				bool loop = false);

			void bezier (
				const Point& p1, const Point& p2, const Point& p3, const Point& p4,
				bool loop = false);

			void bezier (
				const Point* points, size_t size,
				bool loop = false);

			void image (
				const Image& image, coord x = 0, coord y = 0);

			void image (
				const Image& image, const Point& position);

			void image (
				const Image& image, coord x, coord y, coord width, coord height);

			void image (
				const Image& image, const Bounds& bounds);

			void image (
				const Image& image,
				coord  src_x, coord  src_y, coord src_width, coord src_height,
				coord dest_x, coord dest_y);

			void image (
				const Image& image,
				const Bounds& src_bounds, const Point& dest_position);

			void image (
				const Image& image,
				coord  src_x, coord  src_y, coord  src_width, coord  src_height,
				coord dest_x, coord dest_y, coord dest_width, coord dest_height);

			void image (
				const Image& image,
				const Bounds& src_bounds, const Bounds& dest_bounds);

			void text (const char* str, coord x = 0, coord y = 0);

			void text (const char* str, const Point& position);

			void text (const char* str, coord x, coord y, coord width, coord height);

			void text (const char* str, const Bounds& bounds);


			//
			// states
			//
			void     set_background (
				float red, float green, float blue, float alpha = 1, bool clear = true);

			void     set_background (const Color& color, bool clear = true);

			void      no_background (bool clear = true);

			const Color& background () const;

			void     set_fill (float red, float green, float blue, float alpha = 1);

			void     set_fill (const Color& color);

			void      no_fill ();

			const Color& fill () const;

			void     set_stroke (float red, float green, float blue, float alpha = 1);

			void     set_stroke (const Color& color);

			void      no_stroke ();

			const Color& stroke () const;

			void set_stroke_width (coord width);

			coord    stroke_width () const;

			void set_stroke_outset (float outset);

			float    stroke_outset () const;

			void set_stroke_cap (CapType cap);

			CapType  stroke_cap () const;

			void set_stroke_join (JoinType join);

			JoinType stroke_join () const;

			void set_miter_limit (coord limit);

			coord    miter_limit () const;

			void set_nsegment (int nsegment);

			uint     nsegment () const;

			void  set_blend_mode (BlendMode mode);

			BlendMode blend_mode () const;

			void      set_clip (coord x, coord y, coord width, coord height);

			void      set_clip (const Bounds& bounds);

			void       no_clip ();

			const Bounds& clip () const;

			void    set_font (const char* name, coord size = 0);

			void    set_font (const Font& font);

			const Font& font () const;

			void     set_texture (const Image& image);

			void      no_texture ();

			const Image& texture () const;

			void     set_texcoord_mode (TexCoordMode mode);

			TexCoordMode texcoord_mode () const;

			void     set_texcoord_wrap (TexCoordWrap wrap);

			TexCoordWrap texcoord_wrap () const;

			void      set_shader (const Shader& shader);

			void       no_shader ();

			const Shader& shader () const;

			void push_state ();

			void  pop_state ();


			//
			// transformation methods
			//
			void translate (coord x, coord y, coord z = 0);

			void translate (const Point& value);

			void scale (coord x, coord y, coord z = 1);

			void scale (const Point& value);

			void rotate (float degree, coord x = 0, coord y = 0, coord z = 1);

			void rotate (float degree, const Point& normalized_axis);

			void set_matrix (float value = 1);

			void set_matrix (
				float a1, float a2, float a3, float a4,
				float b1, float b2, float b3, float b4,
				float c1, float c2, float c3, float c4,
				float d1, float d2, float d3, float d4);

			void set_matrix (const float* elements, size_t size);

			void set_matrix (const Matrix& matrix);

			const Matrix& matrix () const;

			void push_matrix ();

			void pop_matrix ();


			operator bool () const;

			bool operator ! () const;


			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Painter


}// Rays


#endif//EOH
