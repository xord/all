#include "polyline.h"


#include <assert.h>
#include "rays/debug.h"


using namespace ClipperLib;


namespace Rays
{


	static const char*
	get_mode_name (DrawMode mode)
	{
		switch (mode)
		{
			case DRAW_POLYGON:        return "DRAW_POLYGON";
			case DRAW_POINTS:         return "DRAW_POINTS";
			case DRAW_LINES:          return "DRAW_LINES";
			case DRAW_LINE_STRIP:     return "DRAW_LINE_STRIP";
			case DRAW_LINE_LOOP:      return "DRAW_LINE_LOOP";
			case DRAW_TRIANGLES:      return "DRAW_TRIANGLES";
			case DRAW_TRIANGLE_STRIP: return "DRAW_TRIANGLE_STRIP";
			case DRAW_TRIANGLE_FAN:   return "DRAW_TRIANGLE_FAN";
			case DRAW_QUADS:          return "DRAW_QUADS";
			case DRAW_QUAD_STRIP:     return "DRAW_QUAD_STRIP";
			default: argument_error(__FILE__, __LINE__, "unknown draw mode");
		}
	}

	struct Polyline::Data
	{

		DrawMode mode = DRAW_NONE;

		bool loop     = false;

		PointList points;

		template <typename I, typename FUN>
		void reset (DrawMode mode_, I begin, I end, bool loop_, FUN to_point_fun)
		{
			if (!is_valid_mode(mode_))
			{
				argument_error(
					__FILE__, __LINE__,
					Xot::stringf("polyline does not support '%s'", get_mode_name(mode_)));
			}

			if (begin > end)
				argument_error(__FILE__, __LINE__);

			points.clear();
			points.reserve(end - begin);
			for (auto it = begin; it != end; ++it)
				points.emplace_back(to_point_fun(*it));

			mode = mode_;
			loop = loop_;
		}

		bool is_valid () const
		{
			return is_valid_mode(mode) && !points.empty();
		}

		static bool is_valid_mode (DrawMode mode)
		{
			return
				mode != DRAW_NONE      &&
				mode != DRAW_POINTS    &&
				mode != DRAW_LINES     &&
				mode != DRAW_TRIANGLES &&
				mode != DRAW_QUADS;
		}

	};// Polyline::Data


	void
	Polyline_create (
		Polyline* polyline, const Path& path, bool loop, bool reverse)
	{
		Polyline::Data* self = polyline->self.get();

		Path cleaned;
		ClipperLib::CleanPolygon(path, cleaned);

		auto to_point = [](const IntPoint& point) {return from_clipper(point);};
		if (reverse)
			self->reset(DRAW_POLYGON, cleaned.rbegin(), cleaned.rend(), loop, to_point);
		else
			self->reset(DRAW_POLYGON, cleaned. begin(), cleaned. end(), loop, to_point);
	}

	template <typename I>
	static void
	reset_path (Path* path, I begin, I end)
	{
		path->clear();
		for (auto it = begin; it != end; ++it)
			path->emplace_back(to_clipper(*it));
	}

	void
	Polyline_get_path (Path* path, const Polyline& polyline, bool reverse)
	{
		assert(path);

		const auto& points = polyline.self->points;
		if (reverse)
			reset_path(path, points.rbegin(), points.rend());
		else
			reset_path(path, points. begin(), points. end());
	}


	Polyline::Polyline ()
	{
	}

	Polyline::Polyline (const Point* points, size_t size, bool loop)
	{
		self->reset(
			DRAW_POLYGON, points, points + size, loop,
			[](const Point& p) {return p;});
	}

	Polyline::Polyline (DrawMode mode, const Point* points, size_t size, bool loop)
	{
		self->reset(
			mode, points, points + size, loop,
			[](const Point& p) {return p;});
	}

	Polyline::~Polyline ()
	{
	}

	bool
	Polyline::expand (
		Polygon* result,
		coord width, CapType cap, JoinType join, coord miter_limit) const
	{
		return Polyline_expand(result, *this, width, cap, join, miter_limit);
	}

	Bounds
	Polyline::bounds () const
	{
		if (empty()) return Bounds(-1, -1, -1);

		auto it = begin();
		Bounds b(*it++, 0);
		for (auto end = this->end(); it != end; ++it)
			b |= *it;
		return b;
	}

	DrawMode
	Polyline::mode () const
	{
		return self->mode;
	}

	bool
	Polyline::loop () const
	{
		return self->loop;
	}

	size_t
	Polyline::size () const
	{
		return self->points.size();
	}

	bool
	Polyline::empty () const
	{
		return size() <= 0;
	}

	Polyline::const_iterator
	Polyline::begin () const
	{
		return self->points.begin();
	}

	Polyline::const_iterator
	Polyline::end () const
	{
		return self->points.end();
	}

	const Point&
	Polyline::operator [] (size_t index) const
	{
		return self->points[index];
	}

	Polyline::operator bool () const
	{
		return self->is_valid();
	}

	bool
	Polyline::operator ! () const
	{
		return !operator bool();
	}


}// Rays
