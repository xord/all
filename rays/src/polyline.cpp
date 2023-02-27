#include "polyline.h"


#include <assert.h>
#include "rays/debug.h"


using namespace ClipperLib;


namespace Rays
{


	struct Polyline::Data
	{

		PointList points;

		bool loop = false;

		template <typename I, typename FUN>
		void reset (I begin, I end, bool loop_, FUN to_point_fun)
		{
			size_t size = end - begin;
			if (0 < size && size < 3 && loop_)
				argument_error(__FILE__, __LINE__);

			points.clear();
			points.reserve(size);
			for (auto it = begin; it != end; ++it)
				points.emplace_back(to_point_fun(*it));

			loop = loop_ && size > 0;
		}

	};// Polyline::Data


	void
	Polyline_create (
		Polyline* polyline, const Path& path, bool loop, bool reverse)
	{
		assert(polyline);

		Path cleaned;
		ClipperLib::CleanPolygon(path, cleaned);

		auto to_point = [](const IntPoint& point) {return from_clipper(point);};
		if (reverse)
			polyline->self->reset(cleaned.rbegin(), cleaned.rend(), loop, to_point);
		else
			polyline->self->reset(cleaned. begin(), cleaned. end(), loop, to_point);
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
		self->reset(points, points + size, loop, [](const Point& p) {return p;});
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
		size_t s = size();
		return !((s == 1 || s == 2) && self->loop);
	}

	bool
	Polyline::operator ! () const
	{
		return !operator bool();
	}


}// Rays
