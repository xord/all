#include "polyline.h"


#include <assert.h>
#include "rays/debug.h"


namespace Rays
{


	struct Polyline::Data
	{

		PointList points;

		bool loop = false, fill = false;

		template <typename I, typename FUN>
		void reset (I begin, I end, bool loop_, bool fill_, FUN to_point_fun)
		{
			if (begin > end)
				argument_error(__FILE__, __LINE__);

			points.clear();
			loop = loop_;
			fill = fill_;

			size_t size = end - begin;
			if (size <= 0) return;

			points.reserve(size);
			for (auto it = begin; it != end; ++it)
				points.emplace_back(to_point_fun(*it));
		}

	};// Polyline::Data


	void
	Polyline_create (
		Polyline* polyline, const ClipperPath& path, bool loop, bool hole)
	{
		auto to_point = [](const ClipperPoint& point) {return from_clipper(point);};
		if (hole)
			polyline->self->reset(path.rbegin(), path.rend(), loop, loop, to_point);
		else
			polyline->self->reset(path. begin(), path. end(), loop, loop, to_point);
	}

	template <typename I>
	static void
	reset_path (ClipperPath* path, I begin, I end)
	{
		path->clear();
		for (auto it = begin; it != end; ++it)
			path->emplace_back(to_clipper(*it));
	}

	void
	Polyline_get_path (ClipperPath* path, const Polyline& polyline, bool hole)
	{
		assert(path);

		const auto& points = polyline.self->points;
		if (hole)
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
			points, points + size, loop, loop,
			[](const Point& p) {return p;});
	}

	Polyline::Polyline (const Point* points, size_t size, bool loop, bool fill)
	{
		self->reset(
			points, points + size, loop, fill,
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

	bool
	Polyline::loop () const
	{
		return self->loop;
	}

	bool
	Polyline::fill () const
	{
		return self->fill;
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
		return true;
	}

	bool
	Polyline::operator ! () const
	{
		return !operator bool();
	}


}// Rays
