#include "painter.h"


#include <string.h>
#include <assert.h>
#include "rays/exception.h"
#include "rays/debug.h"
#include "polygon.h"
#include "image.h"


namespace Rays
{


	void
	Painter::Data::set_pixel_density (float density)
	{
		if (density <= 0)
			argument_error(__FILE__, __LINE__, "invalid pixel_density.");

		this->pixel_density = density;
		text_image = Image();
	}


	Painter::~Painter ()
	{
	}

	void
	Painter::canvas (
		coord x, coord y, coord width, coord height, float pixel_density)
	{
		canvas(x, y, 0, width, height, 0, pixel_density);
	}

	void
	Painter::canvas (
		coord x, coord y, coord z, coord width, coord height, coord depth,
		float pixel_density)
	{
		canvas(Bounds(x, y, z, width, height, depth), pixel_density);
	}

	void
	Painter::canvas (const Bounds& viewport, float pixel_density)
	{
		if (!viewport)
			argument_error(__FILE__, __LINE__);

		if (self->is_painting())
			invalid_state_error(__FILE__, __LINE__, "painting flag should be false.");

		self->viewport = viewport;
		self->set_pixel_density(pixel_density);
	}

	const Bounds&
	Painter::bounds () const
	{
		return self->viewport;
	}

	float
	Painter::pixel_density () const
	{
		return self->pixel_density;
	}

	bool
	Painter::painting () const
	{
		return self->is_painting();
	}

	static inline void
	debug_draw_triangulation (
		Painter* painter, const Polygon& polygon, const Color& color)
	{
#ifdef _DEBUG
		assert(painter);

		Color invert_color(
			1.f - color.red,
			1.f - color.green,
			1.f - color.blue);

		Polygon::TrianglePointList triangles;
		if (Polygon_triangulate(&triangles, polygon))
		{
			for (size_t i = 0; i < triangles.size(); i += 3)
				Painter_draw(painter, MODE_LINE_LOOP, &invert_color, &triangles[i], 3);
		}
#endif
	}

	static void
	draw_polygon (
		Painter* painter, const Polygon& polygon,
		coord x, coord y, coord width = 0, coord height = 0, bool resize = false)
	{
		Painter::Data* self = painter->self.get();

		if (!self->is_painting())
			invalid_state_error(__FILE__, __LINE__, "painting flag should be true.");

		if (!self->state.has_color())
			return;

		bool translate = x != 0 || y != 0;
		Matrix matrix(nullptr);
		bool backup = false;

		if (translate || resize)
		{
			matrix = self->position_matrix;
			backup = true;

			if (translate)
				self->position_matrix.translate(x, y);

			if (resize)
			{
				const Bounds& b = polygon.bounds();
				self->position_matrix.scale(width / b.width, height / b.height);
			}
		}

		Color color;

		if (self->state.get_color(&color, FILL))
		{
			Polygon_fill(polygon, painter, color);
			debug_draw_triangulation(painter, polygon, color);
		}

		if (self->state.get_color(&color, STROKE))
			Polygon_stroke(polygon, painter, color);

		if (backup)
			self->position_matrix = matrix;
	}

	void
	Painter::polygon (const Polygon& polygon, const coord x, coord y)
	{
		draw_polygon(this, polygon, x, y);
	}

	void
	Painter::polygon (const Polygon& polygon, const Point& position)
	{
		draw_polygon(this, polygon, position.x, position.y);
	}

	void
	Painter::polygon (
		const Polygon& polygon, coord x, coord y, coord width, coord height)
	{
		draw_polygon(this, polygon, x, y, width, height, true);
	}

	void
	Painter::polygon (const Polygon& polygon, const Bounds& bounds)
	{
		draw_polygon(
			this, polygon, bounds.x, bounds.y, bounds.width, bounds.height, true);
	}

	void
	Painter::point (coord x, coord y)
	{
		polygon(create_point(x, y));
	}

	void
	Painter::point (const Point& point)
	{
		polygon(create_point(point));
	}

	void
	Painter::points (const Point* points, size_t size)
	{
		polygon(create_points(points, size));
	}

	void
	Painter::line (coord x1, coord y1, coord x2, coord y2)
	{
		polygon(create_line(x1, y1, x2, y2));
	}

	void
	Painter::line (const Point& p1, const Point& p2)
	{
		polygon(create_line(p1, p2));
	}

	void
	Painter::line (const Point* points, size_t size, bool loop)
	{
		polygon(create_line(points, size, loop));
	}

	void
	Painter::line (const Polyline& polyline)
	{
		polygon(create_line(polyline));
	}

	void
	Painter::rect (coord x, coord y, coord width, coord height, coord round)
	{
		polygon(create_rect(x, y, width, height, round, nsegment()));
	}

	void
	Painter::rect (
		coord x, coord y, coord width, coord height,
		coord round_left_top,    coord round_right_top,
		coord round_left_bottom, coord round_right_bottom)
	{
		polygon(create_rect(
			x, y, width, height,
			round_left_top,    round_right_top,
			round_left_bottom, round_right_bottom,
			nsegment()));
	}

	void
	Painter::rect (const Bounds& bounds, coord round)
	{
		polygon(create_rect(bounds, round, nsegment()));
	}

	void
	Painter::rect (
		const Bounds& bounds,
		coord round_left_top,    coord round_right_top,
		coord round_left_bottom, coord round_right_bottom)
	{
		polygon(create_rect(
			bounds,
			round_left_top,    round_right_top,
			round_left_bottom, round_right_bottom,
			nsegment()));
	}

	void
	Painter::ellipse (
		coord x, coord y, coord width, coord height,
		const Point& hole_size,
		float angle_from, float angle_to)
	{
		polygon(create_ellipse(
			x, y, width, height, hole_size, angle_from, angle_to, nsegment()));
	}

	void
	Painter::ellipse (
		const Bounds& bounds,
		const Point& hole_size,
		float angle_from, float angle_to)
	{
		polygon(create_ellipse(
			bounds, hole_size, angle_from, angle_to, nsegment()));
	}

	void
	Painter::ellipse (
		const Point& center, const Point& radius, const Point& hole_radius,
		float angle_from, float angle_to)
	{
		polygon(create_ellipse(
			center, radius, hole_radius, angle_from, angle_to, nsegment()));
	}

	void
	Painter::curve (
		coord x1, coord y1, coord x2, coord y2,
		coord x3, coord y3, coord x4, coord y4,
		bool loop)
	{
		polygon(create_curve(x1, y1, x2, y2, x3, y3, x4, y4, loop, nsegment()));
	}

	void
	Painter::curve (
		const Point& p1, const Point& p2, const Point& p3, const Point& p4,
		bool loop)
	{
		polygon(create_curve(p1, p2, p3, p4, loop, nsegment()));
	}

	void
	Painter::curve (const Point* points, size_t size, bool loop)
	{
		polygon(create_curve(points, size, loop, nsegment()));
	}

	void
	Painter::bezier (
		coord x1, coord y1, coord x2, coord y2,
		coord x3, coord y3, coord x4, coord y4,
		bool loop)
	{
		polygon(create_bezier(x1, y1, x2, y2, x3, y3, x4, y4, loop, nsegment()));
	}

	void
	Painter::bezier (
		const Point& p1, const Point& p2, const Point& p3, const Point& p4,
		bool loop)
	{
		polygon(create_bezier(p1, p2, p3, p4, loop, nsegment()));
	}

	void
	Painter::bezier (const Point* points, size_t size, bool loop)
	{
		polygon(create_bezier(points, size, loop, nsegment()));
	}

	void
	Painter_draw_image (
		Painter* painter, const Image& image,
		coord src_x, coord src_y, coord src_w, coord src_h,
		coord dst_x, coord dst_y, coord dst_w, coord dst_h,
		const Shader* shader)
	{
		assert(painter && image);

		Painter::Data* self = painter->self.get();

		if (!self->is_painting())
			invalid_state_error(__FILE__, __LINE__, "painting flag should be true.");

		Color color;
		if (!self->state.get_color(&color, FILL))
			return;

		const Texture& texture = Image_get_texture(image);
		if (!texture)
			invalid_state_error(__FILE__, __LINE__);

		float density = image.pixel_density();
		src_x *= density;
		src_y *= density;
		src_w *= density;
		src_h *= density;

		Point points[4], texcoords[4];
		points[0]   .reset(dst_x,         dst_y);
		points[1]   .reset(dst_x,         dst_y + dst_h);
		points[2]   .reset(dst_x + dst_w, dst_y + dst_h);
		points[3]   .reset(dst_x + dst_w, dst_y);
		texcoords[0].reset(src_x,         src_y);
		texcoords[1].reset(src_x,         src_y + src_h);
		texcoords[2].reset(src_x + src_w, src_y + src_h);
		texcoords[3].reset(src_x + src_w, src_y);

		TextureInfo texinfo(texture, src_x, src_y, src_x + src_w, src_y + src_h);

		Painter_draw(
			painter, MODE_TRIANGLE_FAN, &color, points, 4, NULL, 0, NULL, texcoords,
			&texinfo, shader);
	}

	void
	Painter::image (const Image& image_, coord x, coord y)
	{
		if (!image_)
			argument_error(__FILE__, __LINE__);

		Painter_draw_image(
			this, image_,
			0, 0, image_.width(), image_.height(),
			x, y, image_.width(), image_.height());
	}

	void
	Painter::image (const Image& image_, const Point& position)
	{
		image(image_, position.x, position.y);
	}

	void
	Painter::image (
		const Image& image_, coord x, coord y, coord width, coord height)
	{
		if (!image_)
			argument_error(__FILE__, __LINE__);

		Painter_draw_image(
			this, image_,
			0, 0, image_.width(), image_.height(),
			x, y, width,          height);
	}

	void
	Painter::image (
		const Image& image_, const Bounds& bounds)
	{
		image(image_, bounds.x, bounds.y, bounds.width, bounds.height);
	}

	void
	Painter::image (
		const Image& image_,
		coord src_x, coord src_y, coord src_width, coord src_height,
		coord dst_x, coord dst_y)
	{
		if (!image_)
			argument_error(__FILE__, __LINE__);

		Painter_draw_image(
			this, image_,
			src_x, src_y, src_width,      src_height,
			dst_x, dst_y, image_.width(), image_.height());
	}

	void
	Painter::image (
		const Image& image_, const Bounds& src_bounds, const Point& dst_position)
	{
		image(
			image_,
			src_bounds.x, src_bounds.y, src_bounds.width, src_bounds.height,
			dst_position.x, dst_position.y);
	}

	void
	Painter::image (
		const Image& image_,
		coord src_x, coord src_y, coord src_width, coord src_height,
		coord dst_x, coord dst_y, coord dst_width, coord dst_height)
	{
		if (!image_)
			argument_error(__FILE__, __LINE__);

		Painter_draw_image(
			this, image_,
			src_x, src_y, src_width, src_height,
			dst_x, dst_y, dst_width, dst_height);
	}

	void
	Painter::image (
		const Image& image_, const Bounds& src_bounds, const Bounds& dst_bounds)
	{
		image(
			image_,
			src_bounds.x, src_bounds.y, src_bounds.width, src_bounds.height,
			dst_bounds.x, dst_bounds.y, dst_bounds.width, dst_bounds.height);
	}

	static void
	draw_text (
		Painter* painter, const Font& font,
		const char* str, coord x, coord y, coord width = 0, coord height = 0)
	{
		assert(painter && font && str && *str != '\0');

		Painter::Data* self = painter->self.get();

		if (!self->is_painting())
			invalid_state_error(__FILE__, __LINE__, "painting flag should be true.");

		if (!self->state.has_color())
			return;

		if (!strchr(str, '\n'))
			Painter_draw_text_line(painter, font, str, x, y, width, height);
		else
		{
			coord line_height = painter->line_height();

			StringList lines;
			split(&lines, str, '\n');
			for (const auto& line : lines)
			{
				Painter_draw_text_line(painter, font, line.c_str(), x, y, width, height);
				y += line_height;
			}
		}
	}

	void
	Painter::text (const char* str, coord x, coord y)
	{
		if (!str)
			argument_error(__FILE__, __LINE__);

		if (*str == '\0') return;

		const Font& font = self->state.font;
		if (!font)
			invalid_state_error(__FILE__, __LINE__);

		draw_text(this, font, str, x, y);
	}

	void
	Painter::text (const char* str, const Point& position)
	{
		text(str, position.x, position.y);
	}

	void
	Painter::text (const char* str, coord x, coord y, coord width, coord height)
	{
		if (!str)
			argument_error(__FILE__, __LINE__);

		if (*str == '\0' || width == 0 || height == 0) return;

		const Font& font = self->state.font;
		if (!font)
			invalid_state_error(__FILE__, __LINE__);

		draw_text(this, font, str, x, y, width, height);
	}

	void
	Painter::text (const char* str, const Bounds& bounds)
	{
		text(str, bounds.x, bounds.y, bounds.width, bounds.height);
	}

	void
	Painter::set_background (
		float red, float green, float blue, float alpha, bool clear)
	{
		set_background(Color(red, green, blue, alpha), clear);
	}

	void
	Painter::set_background (const Color& color, bool clear)
	{
		self->state.background = color;

		if (self->is_painting() && clear) this->clear();
	}

	void
	Painter::no_background (bool clear)
	{
		Color c = background();
		c.alpha = 0;
		set_background(c, clear);
	}

	const Color&
	Painter::background () const
	{
		return self->state.background;
	}

	void
	Painter::set_fill (float red, float green, float blue, float alpha)
	{
		set_fill(Color(red, green, blue, alpha));
	}

	void
	Painter::set_fill (const Color& color)
	{
		self->state.  colors[FILL] = color;
		self->state.nocolors[FILL] = false;
	}

	void
	Painter::no_fill ()
	{
		self->state.  colors[FILL].alpha = 0;
		self->state.nocolors[FILL]       = true;
	}

	const Color&
	Painter::fill () const
	{
		return self->state.colors[FILL];
	}

	void
	Painter::set_stroke (float red, float green, float blue, float alpha)
	{
		set_stroke(Color(red, green, blue, alpha));
	}

	void
	Painter::set_stroke (const Color& color)
	{
		self->state.  colors[STROKE] = color;
		self->state.nocolors[STROKE] = false;
	}

	void
	Painter::no_stroke ()
	{
		self->state.  colors[STROKE].alpha = 0;
		self->state.nocolors[STROKE]       = true;
	}

	const Color&
	Painter::stroke () const
	{
		return self->state.colors[STROKE];
	}

	void
	Painter::set_stroke_width (coord width)
	{
		self->state.stroke_width = width;
	}

	coord
	Painter::stroke_width () const
	{
		return self->state.stroke_width;
	}

	void
	Painter::set_stroke_outset (float outset)
	{
		self->state.stroke_outset = outset;
	}

	float
	Painter::stroke_outset () const
	{
		return self->state.stroke_outset;
	}

	void
	Painter::set_stroke_cap (CapType cap)
	{
		self->state.stroke_cap = cap;
	}

	CapType
	Painter::stroke_cap () const
	{
		return self->state.stroke_cap;
	}

	void
	Painter::set_stroke_join (JoinType join)
	{
		self->state.stroke_join = join;
	}

	JoinType
	Painter::stroke_join () const
	{
		return self->state.stroke_join;
	}

	void
	Painter::set_miter_limit (coord limit)
	{
		self->state.miter_limit = limit;
	}

	coord
	Painter::miter_limit () const
	{
		return self->state.miter_limit;
	}

	void
	Painter::set_nsegment (int nsegment)
	{
		if (nsegment < 0) nsegment = 0;
		self->state.nsegment = nsegment;
	}

	uint
	Painter::nsegment () const
	{
		return self->state.nsegment;
	}

	void
	Painter::set_line_height (coord height)
	{
		if (height < 0) height = -1;
		self->state.line_height = height;
	}

	coord
	Painter::line_height (bool raw) const
	{
		coord height = self->state.line_height;
		if (!raw && height < 0) height = self->state.font.get_height();
		return height;
	}

	BlendMode
	Painter::blend_mode () const
	{
		return self->state.blend_mode;
	}

	void
	Painter::set_clip (coord x, coord y, coord width, coord height)
	{
		set_clip(Bounds(x, y, width, height));
	}

	void
	Painter::set_clip (const Bounds& bounds)
	{
		if (bounds == self->state.clip)
			return;

		Painter_flush(this);

		self->state.clip = bounds;
		Painter_update_clip(this);
	}

	void
	Painter::no_clip ()
	{
		set_clip(0, 0, -1, -1);
	}

	const Bounds&
	Painter::clip () const
	{
		return self->state.clip;
	}

	static bool
	has_same_font (const Font& font, const char* name, coord size, bool smooth)
	{
		return
			font.size()   == size &&
			font.smooth() == smooth &&
			font.name()   == (name ? name : get_default_font().name().c_str());
	}

	void
	Painter::set_font (const char* name, coord size, bool smooth)
	{
		if (has_same_font(self->state.font, name, size, smooth)) return;

		set_font(Font(name, size, smooth));
	}

	void
	Painter::set_font (const Font& font)
	{
		self->state.font = font;
	}

	const Font&
	Painter::font () const
	{
		return self->state.font;
	}

	void
	Painter::set_texture (const Image& image)
	{
		if (image == self->state.texture)
			return;

		Painter_flush(this);

		self->state.texture = image;
	}

	void
	Painter::no_texture ()
	{
		if (!self->state.texture) return;

		Painter_flush(this);

		self->state.texture = Image();
	}

	const Image&
	Painter::texture () const
	{
		return self->state.texture;
	}

	void
	Painter::set_texcoord_mode (TexCoordMode mode)
	{
		if (mode == self->state.texcoord_mode)
			return;

		Painter_flush(this);

		self->state.texcoord_mode = mode;
	}

	TexCoordMode
	Painter::texcoord_mode () const
	{
		return self->state.texcoord_mode;
	}

	void
	Painter::set_texcoord_wrap (TexCoordWrap wrap)
	{
		if (wrap == self->state.texcoord_wrap)
			return;

		Painter_flush(this);

		self->state.texcoord_wrap = wrap;
	}

	TexCoordWrap
	Painter::texcoord_wrap () const
	{
		return self->state.texcoord_wrap;
	}

	void
	Painter::set_shader (const Shader& shader)
	{
		if (shader == self->state.shader)
			return;

		Painter_flush(this);

		self->state.shader = shader;
	}

	void
	Painter::no_shader ()
	{
		if (!self->state.shader) return;

		Painter_flush(this);

		self->state.shader = Shader();
	}

	const Shader&
	Painter::shader () const
	{
		return self->state.shader;
	}

	void
	Painter::push_state ()
	{
		self->state_stack.emplace_back(self->state);
	}

	void
	Painter::pop_state ()
	{
		if (self->state_stack.empty())
			invalid_state_error(__FILE__, __LINE__, "state stack underflow.");

		Painter_flush(this);

		self->state = self->state_stack.back();
		self->state_stack.pop_back();
		Painter_update_clip(this);
	}

	void
	Painter::translate (coord x, coord y, coord z)
	{
		self->position_matrix.translate(x, y, z);
	}

	void
	Painter::translate (const Point& value)
	{
		self->position_matrix.translate(value);
	}

	void
	Painter::scale (coord x, coord y, coord z)
	{
		self->position_matrix.scale(x, y, z);
	}

	void
	Painter::scale (const Point& value)
	{
		self->position_matrix.scale(value);
	}

	void
	Painter::rotate (float degree, coord x, coord y, coord z)
	{
		self->position_matrix.rotate(degree, x, y, z);
	}

	void
	Painter::rotate (float angle, const Point& normalized_axis)
	{
		self->position_matrix.rotate(angle, normalized_axis);
	}

	void
	Painter::set_matrix (float value)
	{
		self->position_matrix.reset(value);
	}

	void
	Painter::set_matrix (
		float a1, float a2, float a3, float a4,
		float b1, float b2, float b3, float b4,
		float c1, float c2, float c3, float c4,
		float d1, float d2, float d3, float d4)
	{
		self->position_matrix.reset(
			a1, a2, a3, a4,
			b1, b2, b3, b4,
			c1, c2, c3, c4,
			d1, d2, d3, d4);
	}

	void
	Painter::set_matrix (const coord* elements, size_t size)
	{
		self->position_matrix.reset(elements, size);
	}

	void
	Painter::set_matrix (const Matrix& matrix)
	{
		self->position_matrix = matrix;
	}

	const Matrix&
	Painter::matrix () const
	{
		return self->position_matrix;
	}

	void
	Painter::push_matrix ()
	{
		self->position_matrix_stack.emplace_back(self->position_matrix);
	}

	void
	Painter::pop_matrix ()
	{
		if (self->position_matrix_stack.empty())
			invalid_state_error(__FILE__, __LINE__, "matrix stack underflow.");

		self->position_matrix = self->position_matrix_stack.back();
		self->position_matrix_stack.pop_back();
	}

	void
	Painter::add_flag (uint flags)
	{
		Xot::add_flag(&self->flags, flags);
	}

	void
	Painter::remove_flag (uint flags)
	{
		Xot::remove_flag(&self->flags, flags);
	}

	bool
	Painter::has_flag (uint flags) const
	{
		return Xot::has_flag(self->flags, flags);
	}

	Painter::operator bool () const
	{
		return self->viewport;
	}

	bool
	Painter::operator ! () const
	{
		return !operator bool();
	}

	static bool g_debug = false;

	void
	Painter::set_debug (bool debug)
	{
		g_debug = debug;
	}

	bool
	Painter::debug ()
	{
		return g_debug;
	}


}// Rays
