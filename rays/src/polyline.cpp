#include "polyline.h"


#include <assert.h>
#include <memory>
#include "rays/color.h"
#include "rays/debug.h"


using namespace ClipperLib;


namespace Rays
{


	struct Polyline::Data
	{

		typedef std::vector<Color>  ColorList;

		typedef std::vector<Coord3> TexCoordList;

		PointList points;

		std::unique_ptr<ColorList>    pcolors;

		std::unique_ptr<TexCoordList> ptexcoords;

		bool loop = false, fill = false;

		void reset (
			const auto* points_, const Color* colors_, const Coord3* texcoords_,
			size_t size_, bool loop, bool fill, bool hole,
			auto to_point_fun)
		{
			ColorList* colors       = colors_    ? &this->colors()    : NULL;
			TexCoordList* texcoords = texcoords_ ? &this->texcoords() : NULL;
			int size                = (int) size_;

			this->loop = loop;
			this->fill = fill;

			points.clear();
			points.reserve(size);
			if (hole)
			{
				for (int i = size - 1; i >= 0; --i)
					points.emplace_back(to_point_fun(points_[i]));
			}
			else
			{
				for (int i = 0; i < size; ++i)
					points.emplace_back(to_point_fun(points_[i]));
			}

			if (colors)
			{
				colors->clear();
				colors->reserve(size);
				if (hole)
				{
					for (int i = size - 1; i >= 0; --i)
						colors->emplace_back(colors_[i]);
				}
				else
				{
					for (int i = 0; i < size; ++i)
						colors->emplace_back(colors_[i]);
				}
			}

			if (texcoords)
			{
				texcoords->clear();
				texcoords->reserve(size);
				if (hole)
				{
					for (int i = size - 1; i >= 0; --i)
						texcoords->emplace_back(texcoords_[i]);
				}
				else
				{
					for (int i = 0; i < size; ++i)
						texcoords->emplace_back(texcoords_[i]);
				}
			}
		}

		ColorList& colors ()
		{
			if (!pcolors) pcolors.reset(new ColorList());
			return *pcolors;
		}

		TexCoordList& texcoords ()
		{
			if (!ptexcoords) ptexcoords.reset(new TexCoordList());
			return *ptexcoords;
		}

		private:
#if 0
			void reset_values (size_t size_, bool hole, auto fun)
			{
				int size = (int) size_;

				if (hole)
					for (int i = size - 1; i >= 0;   --i) fun((size_t) i);
				else
					for (int i = 0;        i < size; ++i) fun((size_t) i);
			}
#endif
	};// Polyline::Data


	void
	Polyline_create (
		Polyline* polyline, const Path& path, bool loop, bool hole)
	{
		Path cleaned;
		ClipperLib::CleanPolygon(path, cleaned);

		polyline->self->reset(
			&cleaned[0], NULL, NULL, cleaned.size(), loop, loop, hole,
			[](const IntPoint& point) {return from_clipper(point);});
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
	Polyline_get_path (Path* path, const Polyline& polyline, bool hole)
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

	Polyline::Polyline (
		const Point* points, size_t size, bool loop,
		const Color* colors, const Coord3* texcoords)
	{
		self->reset(
			points, colors, texcoords, size, loop, loop, false,
			[](const Point& p) {return p;});
	}

	Polyline::Polyline (
		const Point* points, size_t size, bool loop, bool fill,
		const Color* colors, const Coord3* texcoords)
	{
		self->reset(
			points, colors, texcoords, size, loop, fill, false,
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

	const Point*
	Polyline::points () const
	{
		const auto& v = self->points;
		return !v.empty() ? &v[0] : NULL;
	}

	const Color*
	Polyline::colors () const
	{
		const auto& pv = self->pcolors;
		return pv && !pv->empty() ? &(*pv)[0] : NULL;
	}

	const Coord3*
	Polyline::texcoords () const
	{
		const auto& pv = self->ptexcoords;
		return pv && !pv->empty() ? &(*pv)[0] : NULL;
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
