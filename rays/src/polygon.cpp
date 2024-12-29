#include "polygon.h"


#include <math.h>
#include <assert.h>
#include <utility>
#include <earcut.hpp>
#include <Splines.h>
#include <xot/util.h>
#include "rays/color.h"
#include "rays/exception.h"
#include "rays/debug.h"
#include "polyline.h"
#include "painter.h"


namespace clip = ClipperLib;


namespace mapbox
{

	namespace util
	{

		template<>
		struct nth<0, Rays::Point>
		{
			inline static auto get (const Rays::Point& p)
			{
				return p.x;
			}
		};

		template<>
		struct nth<1, Rays::Point>
		{
			inline static auto get (const Rays::Point& p)
			{
				return p.y;
			}
		};

	}// util

}// mapbox


namespace Rays
{


	class Triangles
	{

		public:

			Triangles (size_t npoints)
			{
				points.reserve(npoints);
			}

			void append (const Polyline& polyline)
			{
				if (polyline.empty()) return;

				const Point* points_     = polyline.points();
				const Color* colors_     = polyline.colors();
				const Coord3* texcoords_ = polyline.texcoords();
				if (!points_)
					argument_error(__FILE__, __LINE__);

				if (!points.empty() && !colors_ != !pcolors)
					argument_error(__FILE__, __LINE__);
				if (!points.empty() && !texcoords_ != !ptexcoords)
					argument_error(__FILE__, __LINE__);

				segments.emplace_back(points.size(), 0, polyline.hole());
				points.insert(points.end(), points_, points_ + polyline.size());
				segments.back().end = points.size();

				if (colors_)
				{
					if (!pcolors)
					{
						pcolors.reset(new decltype(pcolors)::element_type());
						pcolors->reserve(points.capacity());
					}
					pcolors->insert(pcolors->end(), colors_, colors_ + polyline.size());
				}

				if (texcoords_)
				{
					if (!ptexcoords)
					{
						ptexcoords.reset(new decltype(ptexcoords)::element_type());
						ptexcoords->reserve(points.capacity());
					}
					ptexcoords->insert(
						ptexcoords->end(), texcoords_, texcoords_ + polyline.size());
				}
			}

			bool get (Polygon::TrianglePointList* triangles) const
			{
				triangulate();
				if (indices.empty()) return false;

				triangles->reserve(triangles->size() + indices.size());
				for (const auto& index : indices)
					triangles->emplace_back(points[index]);
				return true;
			}

			void draw (Painter* painter, const Color& color) const
			{
				triangulate();
				if (indices.empty()) return;

				if (pcolors)
				{
					Painter_draw(
						painter, GL_TRIANGLES,
						&points[0],  points.size(),
						&indices[0], indices.size(),
						&(*pcolors)[0],
						ptexcoords ? &(*ptexcoords)[0] : NULL);
				}
				else
				{
					Painter_draw(
						painter, GL_TRIANGLES, color,
						&points[0],  points.size(),
						&indices[0], indices.size(),
						ptexcoords ? &(*ptexcoords)[0] : NULL);
				}
			}

		private:

			struct Segment
			{

				size_t begin, end;

				bool hole;

				Segment (size_t begin, size_t end, bool hole = false)
				:	begin(begin), end(end), hole(hole)
				{
				}

				bool empty () const
				{
					return begin == end;
				}

			};// Segment

			class Polyline
			{

				const Point* points;

				size_t size_;

				public:

					typedef Point value_type;

					Polyline (const Point* points, size_t size)
					:	points(points), size_(size)
					{
					}

					size_t size () const {return size_;}

					bool empty () const {return size_ == 0;}

					const Point& operator [] (size_t i) const {return points[i];}

			};// Polyline

			typedef std::vector<Polyline> PolylineList;

			std::vector<Point> points;

			std::unique_ptr<std::vector<Color>> pcolors;

			std::unique_ptr<std::vector<Coord3>> ptexcoords;

			mutable std::vector<Segment> segments;

			mutable std::vector<uint32_t> indices;

			void triangulate () const
			{
				if (segments.empty()) return;

				PolylineList polylines;
				size_t index_offset = 0;
				for (const auto& seg : segments)
				{
					Polyline polyline(&points[0] + seg.begin, seg.end - seg.begin);
					if (!seg.hole)
					{
						triangulate(polylines, index_offset);
						polylines.clear();
						index_offset = seg.begin;
					}
					polylines.emplace_back(polyline);
				}
				triangulate(polylines, index_offset);

				segments.clear();
				segments.shrink_to_fit();
			}

			void triangulate (const PolylineList& polylines, size_t index_offset) const
			{
				if (polylines.empty()) return;

				auto result = mapbox::earcut<uint32_t>(polylines);
				for (const auto& index : result)
					indices.emplace_back(index_offset + index);
			}

	};// Triangles


	struct Polygon::Data
	{

		PolylineList polylines;

		mutable std::unique_ptr<Bounds>    pbounds;

		mutable std::unique_ptr<Triangles> ptriangles;

		virtual ~Data ()
		{
		}

		const Bounds& bounds () const
		{
			if (!pbounds)
			{
				if (polylines.empty())
					pbounds.reset(new Bounds(-1, -1, -1));
				else
				{
					pbounds.reset(new Bounds(polylines[0][0], 0));
					for (const auto& polyline : polylines)
					{
						for (const auto& point : polyline)
							*pbounds |= point;
					}
				}
			}
			return *pbounds;
		}

		void append (const Polyline& polyline)
		{
			if (polyline.empty())
				return;

			polylines.emplace_back(polyline);
		}

		bool triangulate (TrianglePointList* triangles) const
		{
			triangles->clear();
			return this->triangles().get(triangles);
		}

		virtual void fill (Painter* painter, const Color& color) const
		{
			triangles().draw(painter, color);
		}

		virtual void stroke (
			const Polygon& polygon, Painter* painter, const Color& color) const
		{
			assert(painter && color);

			coord stroke_width = painter->stroke_width();
			if (stroke_width > 0)
			{
				stroke_with_width(
					polygon, painter, color, stroke_width, painter->stroke_outset());
			}
			else
				stroke_without_width(painter, color);
		}

		private:

			Triangles& triangles () const
			{
				if (!ptriangles)
				{
					ptriangles.reset(new Triangles(count_points_for_triangulation()));
					for (const auto& polyline : polylines)
						ptriangles->append(polyline);
				}
				return *ptriangles;
			}

			size_t count_points_for_triangulation () const
			{
				size_t count = 0;
				for (const auto& polyline : polylines)
				{
					if (can_triangulate(polyline))
						count += polyline.size();
				}
				return count;
			}

			bool can_triangulate (const Polyline& polyline) const
			{
				return (polyline.fill() || polyline.hole()) && polyline.size() >= 3;
			}

			void stroke_with_width (
				const Polygon& polygon, Painter* painter,
				const Color& color, coord stroke_width, float stroke_outset) const
			{
				assert(painter && color && stroke_width > 0);

				if (!polygon || polygon.empty()) return;

				CapType cap   = painter->stroke_cap();
				JoinType join = painter->stroke_join();
				coord ml      = painter->miter_limit();

				bool has_loop = false;
				for (const auto& polyline : polygon)
				{
					if (polyline.loop())
					{
						has_loop = true;
						continue;
					}
					stroke_polyline(polyline, painter, color, stroke_width, cap, join, ml);
				}

				if (!has_loop) return;

				coord inset = (-0.5 + stroke_outset) * stroke_width;
				Polygon outline;
				if (inset == 0)
					outline = polygon;
				else if (!polygon.expand(&outline, inset, cap, join, ml))
					return;

				for (const auto& polyline : outline)
				{
					if (polyline.loop())
						stroke_polyline(polyline, painter, color, stroke_width, cap, join, ml);
				}
			}

			void stroke_polyline (
				const Polyline& polyline, Painter* painter,
				const Color& color, coord stroke_width,
				CapType cap, JoinType join, coord miter_limit) const
			{
				assert(stroke_width > 0);

				if (!polyline || polyline.empty())
					return;

				Polygon stroke;
				if (polyline.expand(&stroke, stroke_width / 2, cap, join, miter_limit))
					Polygon_fill(stroke, painter, color);
			}

			void stroke_without_width (Painter* painter, const Color& color) const
			{
				assert(painter && color);

				for (const auto& polyline : polylines)
				{
					Painter_draw(
						painter, polyline.loop() ? GL_LINE_LOOP : GL_LINE_STRIP, color,
						&polyline[0], polyline.size());
				}
			}

	};// Polygon::Data


#if 0
	static String
	path2str (const Path& path)
	{
		String s;
		for (const auto& point : path)
		{
			if (!s.empty()) s += ", ";

			Point p = from_clipper(point);
			s += Xot::stringf("[%d,%d]", p.x, p.y);
		}
		return s;
	}

	static void
	dout_node (const PolyNode& node)
	{
		doutln(
			"path(open: %d, hole: %d, Contour: %s)",
			(int) node.IsOpen(),
			(int) node.IsHole(),
			path2str(node.Contour).c_str());
	}

	static void
	dout_tree (const PolyNode& node, int level = 0)
	{
		for (int i = 0; i < level; ++i) dout("  ");
		dout_node(node);

		for (const auto* child : node.Childs)
			dout_tree(*child, level + 1);
	}
#endif

	static uint
	get_nsegment_for_angle (
		uint nsegment, uint nsegment_min, float angle_from, float angle_to)
	{
		float angle = angle_to - angle_from;
		assert(0 <= angle && angle <= 360);

		if (nsegment <= 0)
			nsegment = 32;
		else if (nsegment < nsegment_min)
			nsegment = nsegment_min;

		nsegment *= angle / 360;
		return nsegment > 0 ? nsegment : 1;
	}

	static void
	add_polygon_to_clipper (
		clip::Clipper* clipper, const Polygon& polygon, clip::PolyType type)
	{
		assert(clipper);

		clip::Path path;
		for (const auto& polyline : polygon)
		{
			if (!polyline) continue;

			Polyline_get_path(&path, polyline, polyline.hole());
			if (path.empty()) continue;

			clipper->AddPath(path, type, polyline.loop());
		}
	}

	static clip::JoinType
	get_join_type (JoinType join)
	{
		switch (join)
		{
			case JOIN_MITER:  return clip::jtMiter;
			case JOIN_ROUND:  return clip::jtRound;
			case JOIN_SQUARE: return clip::jtSquare;
			default:
				argument_error(__FILE__, __LINE__, "invalid join type -- %d", join);
		}

		return clip::jtMiter;// to avoid compiler warning
	}

	static clip::EndType
	get_end_type (const Polyline& polyline, CapType cap, bool fill)
	{
		if (polyline.loop())
			return fill ? clip::etClosedPolygon : clip::etClosedLine;
		else switch (cap)
		{
			case CAP_BUTT:   return clip::etOpenButt;
			case CAP_ROUND:  return clip::etOpenRound;
			case CAP_SQUARE: return clip::etOpenSquare;
			default:
				argument_error(__FILE__, __LINE__, "invalid cap type -- %d", cap);
		}

		return clip::etOpenButt;// to avoid compiler warning
	}

	static bool
	add_polyline_to_offsetter (
		clip::ClipperOffset* offsetter, const Polyline& polyline,
		CapType cap, JoinType join, bool fill, bool hole)
	{
		assert(offsetter);

		if (!polyline) return false;

		clip::Path path;
		Polyline_get_path(&path, polyline, hole);
		offsetter->AddPath(
			path, get_join_type(join), get_end_type(polyline, cap, fill));
		return true;
	}

	static bool
	add_polygon_to_offsetter (
		clip::ClipperOffset* offsetter, const Polygon& polygon,
		CapType cap, JoinType join)
	{
		assert(offsetter);

		bool added = false;
		for (const auto& polyline : polygon.self->polylines)
		{
			added |= add_polyline_to_offsetter(
				offsetter, polyline, cap, join, true, polyline.hole());
		}
		return added;
	}

	static bool
	append_outline (Polygon* polygon, const clip::PolyNode& node)
	{
		assert(polygon);

		if (node.Contour.empty() || node.IsHole())
			return false;

		Polyline polyline = Polyline_create(node.Contour, !node.IsOpen());
		if (!polyline)
			return false;

		polygon->self->append(polyline);
		return true;
	}

	static void
	append_hole (Polygon* polygon, const clip::PolyNode& node)
	{
		assert(polygon);

		for (const auto* child : node.Childs)
		{
			if (!child->IsHole())
				return;

			Polyline polyline = Polyline_create(child->Contour, !child->IsOpen(), true);
			if (!polyline)
				continue;

			polygon->self->append(polyline);
		}
	}

	static void
	get_polygon (Polygon* polygon, const clip::PolyNode& node)
	{
		assert(polygon);

		if (append_outline(polygon, node))
			append_hole(polygon, node);

		for (const auto* child : node.Childs)
			get_polygon(polygon, *child);
	}

	static Polygon
	clip_polygons (
		const Polygon& subject, const Polygon& clip, clip::ClipType type)
	{
		clip::Clipper c;
		c.StrictlySimple(true);

		add_polygon_to_clipper(&c, subject, clip::ptSubject);
		add_polygon_to_clipper(&c, clip,    clip::ptClip);

		clip::PolyTree tree;
		c.Execute(type, tree);
		assert(tree.Contour.empty());

		Polygon result;
		get_polygon(&result, tree);

		return result;
	}

	static bool
	expand_polygon (
		Polygon* result, const Polygon& polygon,
		coord width, CapType cap, JoinType join, coord miter_limit)
	{
		if (width == 0)
			return false;

		clip::ClipperOffset co;
		co.MiterLimit = miter_limit;
		if (!add_polygon_to_offsetter(&co, polygon, cap, join))
			return false;

		clip::PolyTree tree;
		co.Execute(tree, to_clipper(width));
		assert(tree.Contour.empty());

		get_polygon(result, tree);
		return true;
	}

	bool
	Polyline_expand (
		Polygon* result, const Polyline& polyline,
		coord width, CapType cap, JoinType join, coord miter_limit)
	{
		if (width == 0)
			return false;

		clip::ClipperOffset co;
		co.MiterLimit = miter_limit;
		if (!add_polyline_to_offsetter(&co, polyline, cap, join, false, false))
			return false;

		clip::PolyTree tree;
		co.Execute(tree, to_clipper(width));
		assert(tree.Contour.empty());

		get_polygon(result, tree);
		return true;
	}


	struct RectData : public Polygon::Data
	{

		RectData (
			coord x, coord y, coord width, coord height,
			coord round_left_top,    coord round_right_top,
			coord round_left_bottom, coord round_right_bottom,
			uint nsegment)
		{
			if (
				round_left_top    == 0 && round_right_top    == 0 &&
				round_left_bottom == 0 && round_right_bottom == 0)
			{
				setup_rect(x, y, width, height);
			}
			else
			{
				setup_round_rect(
					x, y, width, height,
					round_left_top,    round_right_top,
					round_left_bottom, round_right_bottom,
					nsegment);
			}
		}

		void fill (Painter* painter, const Color& color) const
		{
			if (polylines.size() != 1)
				invalid_state_error(__FILE__, __LINE__);

			const auto& outline = polylines[0];
			Painter_draw(
				painter, GL_TRIANGLE_FAN, color, &outline[0], outline.size());
		}

		private:

			struct RoundedCorner
			{
				coord x, y, offset_sign_x, offset_sign_y, round;
			};

			void setup_rect (coord x, coord y, coord width, coord height)
			{
				const Point points[] = {
					Point(x,         y),
					Point(x,         y + height),
					Point(x + width, y + height),
					Point(x + width, y),
				};
				append(Polyline(points, 4, true));
			}

			void setup_round_rect (
				coord x, coord y, coord width, coord height,
				coord left_top, coord right_top, coord left_bottom, coord right_bottom,
				uint nsegment)
			{
				assert(width != 0 && height != 0);
				assert(
					left_top    != 0 || right_top    != 0 ||
					left_bottom != 0 || right_bottom != 0);

				nsegment = get_nsegment_for_angle(nsegment, 1, 0, 90);

				fix_rounds(
					&left_top,    &right_top,
					&left_bottom, &right_bottom,
					width, height);

				coord sign_x            = width  >= 0 ? +1 : -1;
				coord sign_y            = height >= 0 ? +1 : -1;
				RoundedCorner corners[] =
				{
					{width,      0, -1, +1, right_top},
					{    0,      0, +1, +1,  left_top},
					{    0, height, +1, -1,  left_bottom},
					{width, height, -1, -1, right_bottom}
				};

				size_t npoints = 0;
				for (size_t i = 0; i < 4; ++i)
					npoints += corners[i].round > 0 ? nsegment + 1 : 1;

				std::unique_ptr<Point[]> points(new Point[npoints]);
				Point* point = points.get();

				for (size_t i = 0; i < 4; ++i)
				{
					point += setup_round(
						point, x, y, corners[i], sign_x, sign_y, (M_PI / 2) * i, nsegment);
				}

				append(Polyline(points.get(), npoints, true));
			}

			void fix_rounds (
				coord* left_top,    coord* right_top,
				coord* left_bottom, coord* right_bottom,
				coord width, coord height)
			{
				assert(
					left_top    && right_top &&
					left_bottom && right_bottom);

				if (width  < 0) width  = -width;
				if (height < 0) height = -height;

				coord* rounds[] = {
					 left_top,
					right_top,
					right_bottom,
					 left_bottom,
					 left_top};
				coord sizes[]   = {width, height, width, height};

				for (size_t i = 0; i < 4; ++i)
				{
					const coord& size = sizes[i];

					coord* a = rounds[i];
					coord* b = rounds[i + 1];
					if (*a + *b <= size)
						continue;

					if (*a > *b)
						std::swap(a, b);

					if (*a * 2 > size)
						*a = *b = size / 2;
					else
						*b = size - *a;
				}
			}

			int setup_round (
				Point* point, coord x, coord y, const RoundedCorner& corner,
				coord sign_x, coord sign_y, float radian_offset, uint nsegment)
			{
				if (corner.round <= 0)
				{
					point->reset(x + corner.x, y + corner.y);
					return 1;
				}

				coord offset_x = corner.x + corner.round * corner.offset_sign_x * sign_x;
				coord offset_y = corner.y + corner.round * corner.offset_sign_y * sign_y;

				for (uint seg = 0; seg <= nsegment; ++seg, ++point)
				{
					float pos    = (float) seg / (float) nsegment;
					float radian = radian_offset + pos * (M_PI / 2);
					point->reset(
						x + offset_x + cos(radian) * corner.round * sign_x,
						y + offset_y - sin(radian) * corner.round * sign_y);
				}
				return nsegment + 1;
			}

	};// RectData


	struct EllipseData : public Polygon::Data
	{

		typedef Polygon::Data Super;

		GLenum mode = 0;

		EllipseData (
			coord x, coord y, coord width, coord height,
			const Point& hole_size,
			float angle_from, float angle_to,
			uint nsegment)
		{
			normalize_angle(&angle_from, &angle_to);

			if ((angle_to - angle_from) >= 360)
				setup_ellipse(x, y, width, height, hole_size, nsegment);
			else
			{
				setup_arc(
					x, y, width, height, hole_size, angle_from, angle_to, nsegment);
			}
		}

		void fill (Painter* painter, const Color& color) const
		{
			if (polylines.size() <= 0)
				invalid_state_error(__FILE__, __LINE__);

			if (mode == 0)
			{
				Super::fill(painter, color);
				return;
			}

			if (polylines.size() >= 2)
				invalid_state_error(__FILE__, __LINE__);

			const auto& outline = polylines[0];
			Painter_draw(painter, mode, color, &outline[0], outline.size());
		}

		private:

			void normalize_angle (float* angle_from, float* angle_to)
			{
				assert(angle_from && angle_to);

				float& from = *angle_from;
				float& to   = *angle_to;

				if (from > to)
					std::swap(from, to);

				if (to - from > 360)
					to = from + 360;
			}

			void setup_ellipse (
				coord x, coord y, coord width, coord height,
				const Point& hole_size, uint nsegment)
			{
				assert(width != 0 && height != 0);

				nsegment = get_nsegment_for_angle(nsegment, 3, 0, 360);

				bool has_hole     = hole_size != 0;
				float radian_from = Xot::deg2rad(0);
				float radian_to   = Xot::deg2rad(360);

				if (!has_hole) mode = GL_TRIANGLE_FAN;

				std::vector<Point> points;
				points.reserve(nsegment);

				for (uint seg = 0; seg < nsegment; ++seg)
				{
					points.emplace_back(make_ellipse_point(
						x, y, width, height, radian_from, radian_to, nsegment, seg));
				}
				append(Polyline(&points[0], points.size(), true));

				if (has_hole)
				{
					points.clear();

					coord hole_x = x + (width  - hole_size.x) / 2;
					coord hole_y = y + (height - hole_size.y) / 2;
					for (uint seg = 0; seg < nsegment; ++seg)
					{
						points.emplace_back(make_ellipse_point(
							hole_x, hole_y, hole_size.x, hole_size.y,
							radian_from, radian_to, nsegment, seg));
					}
					append(Polyline(&points[0], points.size(), true, NULL, NULL, true));
				}
			}

			void setup_arc (
				coord x, coord y, coord width, coord height,
				const Point& hole_size, float angle_from, float angle_to,
				uint nsegment)
			{
				assert(width != 0 && height != 0 && angle_from != angle_to);

				nsegment = get_nsegment_for_angle(nsegment, 3, angle_from, angle_to);

				bool has_hole     = hole_size != 0;
				float radian_from = Xot::deg2rad(angle_from);
				float radian_to   = Xot::deg2rad(angle_to);
				uint npoint       = nsegment + 1;

				std::vector<Point> points;
				points.reserve(has_hole ? npoint * 2 : npoint + 1);

				if (!has_hole)
				{
					points.emplace_back(x + width / 2, y + height / 2);
					mode = GL_TRIANGLE_FAN;
				}

				for (uint seg = 0; seg <= nsegment; ++seg)
				{
					points.emplace_back(make_ellipse_point(
						x, y, width, height, radian_from, radian_to, nsegment, seg));
				}

				if (has_hole)
				{
					coord hole_x = x + (width  - hole_size.x) / 2;
					coord hole_y = y + (height - hole_size.y) / 2;
					for (uint seg = 0; seg <= nsegment; ++seg)
					{
						points.emplace_back(make_ellipse_point(
							hole_x, hole_y, hole_size.x, hole_size.y,
							radian_from, radian_to, nsegment, nsegment - seg));
					}
				}

				append(Polyline(&points[0], points.size(), true));
			}

			Point make_ellipse_point (
				coord x, coord y, coord width, coord height,
				float radian_from, float radian_to,
				uint segment_max, uint segment_index)
			{
				float pos    = (float) segment_index / (float) segment_max;
				float radian = radian_from + (radian_to - radian_from) * pos;
				float cos_   = (cos(radian)  + 1) / 2.;
				float sin_   = (-sin(radian) + 1) / 2.;
				return Point(
					x + width  * cos_,
					y + height * sin_);
			}

	};// EllipseData


	Polygon
	create_point (coord x, coord y)
	{
		return create_point(Point(x, y));
	}

	Polygon
	create_point (const Point& point)
	{
		return create_points(&point, 1);
	}

	Polygon
	create_points (const Point* points, size_t size)
	{
		static const coord DELTA = 0.01;

		Polygon p;
		for (size_t i = 0; i < size; ++i)
		{
			// Polyline(&points[i], 1, false, false).expand() ignores CapType

			coord x = points[i].x, y = points[i].y;
			Point array[] = {{x, y}, {x + DELTA, y + DELTA}};
			p.self->append(Polyline(array, 2, false, false));
		}
		return p;
	}

	Polygon
	create_line (coord x1, coord y1, coord x2, coord y2)
	{
		const Point points[] = {
			Point(x1, y1),
			Point(x2, y2)
		};
		return create_line(points, 2);
	}

	Polygon
	create_line (const Point& p1, const Point& p2)
	{
		const Point points[] = {p1, p2};
		return create_line(points, 2);
	}

	Polygon
	create_line (const Point* points, size_t size, bool loop)
	{
		Polygon p;(points, size, loop);
		//if (!loop || size < 3)
			p.self->append(Polyline(points, size, loop, false));
#if 0
		else
		{
			std::vector<Point> array;
			array.reserve(size + 1);
			array.insert(array.begin(), points, points + size);
			array.emplace_back(points[0]);
			polygon->self->append(Polyline(&array[0], array.size(), true, false));
		}
#endif
		return p;
	}

	Polygon
	create_line (const Polyline& polyline)
	{
		return Polygon(polyline);
	}

	Polygon
	create_lines (const Point* points, size_t size)
	{
		Polygon p;
		for (size_t i = 0; i + 1 < size; i += 2)
			p.self->append(Polyline(&points[i], 2, false, false));
		return p;
	}

	Polygon
	create_triangle (
		coord x1, coord y1, coord x2, coord y2, coord x3, coord y3, bool loop)
	{
		const Point points[] = {Point(x1, y1), Point(x2, y2), Point(x3, y3)};
		return create_triangles(points, 3, loop);
	}

	Polygon
	create_triangle (
		const Point& p1, const Point& p2, const Point& p3, bool loop)
	{
		const Point points[] = {p1, p2, p3};
		return create_triangles(points, 3, loop);
	}

	Polygon
	create_triangles (
		const Point* points, size_t size, bool loop,
		const Color* colors, const Coord3* texcoords)
	{
		Polygon p;
		for (size_t i = 0; i + 2 < size; i += 3)
		{
			p.self->append(Polyline(
				&points[i], 3, loop, true,
				colors    ? &colors[i]    : NULL,
				texcoords ? &texcoords[i] : NULL));
		}
		return p;
	}

	Polygon
	create_triangle_strip (
		const Point* points, size_t size,
		const Color* colors, const Coord3* texcoords)
	{
		Polygon p;
		if (size < 3) return p;

		size_t     last = size - 1;
		size_t  in_last = last % 2 == 0 ? last - 1 : last;
		size_t out_last = last % 2 == 0 ? last     : last - 1;

		std::vector<Point> points_;
		points_.reserve(size);
		points_.emplace_back(points[0]);
		for (size_t i = 1; i <= in_last; i += 2)
			points_.emplace_back(points[i]);
		for (size_t i = out_last; i >= 2; i -= 2)
			points_.emplace_back(points[i]);

		std::unique_ptr<std::vector<Color>> pcolors_;
		if (colors)
		{
			pcolors_.reset(new decltype(pcolors_)::element_type());
			pcolors_->reserve(size);
			pcolors_->emplace_back(colors[0]);
			for (size_t i = 1; i <= in_last; i += 2)
				pcolors_->emplace_back(colors[i]);
			for (size_t i = out_last; i >= 2; i -= 2)
				pcolors_->emplace_back(colors[i]);
		}

		std::unique_ptr<std::vector<Coord3>> ptexcoords_;
		if (texcoords)
		{
			ptexcoords_.reset(new decltype(ptexcoords_)::element_type());
			ptexcoords_->reserve(size);
			ptexcoords_->emplace_back(texcoords[0]);
			for (size_t i = 1; i <= in_last; i += 2)
				ptexcoords_->emplace_back(texcoords[i]);
			for (size_t i = out_last; i >= 2; i -= 2)
				ptexcoords_->emplace_back(texcoords[i]);
		}

		p.self->append(Polyline(
			&points_[0], points_.size(), true,
			pcolors_    ? &(*pcolors_)[0]    : NULL,
			ptexcoords_ ? &(*ptexcoords_)[0] : NULL));
		if (size >= 4)
		{
			p.self->append(Polyline(
				&points[1], size - 2, false,
				colors    ? &colors[1]    : NULL,
				texcoords ? &texcoords[1] : NULL));
		}
		return p;
	}

	Polygon
	create_triangle_fan (
		const Point* points, size_t size,
		const Color* colors, const Coord3* texcoords)
	{
		Polygon p(points, size, true, colors, texcoords);

		Point array[2];
		array[0] = points[0];
		for (size_t i = 2; i < size - 1; ++i)
		{
			array[1] = points[i];
			p.self->append(Polyline(
				&array[0], 2, false,
				colors    ? &colors[0]    : NULL,
				texcoords ? &texcoords[0] : NULL));
		}
		return p;
	}

	Polygon
	create_rect (
		coord x, coord y, coord width, coord height,
		coord round, uint nsegment)
	{
		return create_rect(
			x, y, width, height, round, round, round, round, nsegment);
	}

	Polygon
	create_rect (
		coord x, coord y, coord width, coord height,
		coord round_left_top,    coord round_right_top,
		coord round_left_bottom, coord round_right_bottom,
		uint nsegment)
	{
		if (width == 0 || height == 0)
			return Polygon();

		return Polygon(new RectData(
			x, y, width, height,
			round_left_top,    round_right_top,
			round_left_bottom, round_right_bottom,
			nsegment));
	}

	Polygon
	create_rect (const Bounds& bounds, coord round, uint nsegment)
	{
		return create_rect(
			bounds.x, bounds.y, bounds.width, bounds.height,
			round, round, round, round,
			nsegment);
	}

	Polygon
	create_rect (
		const Bounds& bounds,
		coord round_left_top,    coord round_right_top,
		coord round_left_bottom, coord round_right_bottom,
		uint nsegment)
	{
		return create_rect(
			bounds.x, bounds.y, bounds.width, bounds.height,
			round_left_top,    round_right_top,
			round_left_bottom, round_right_bottom,
			nsegment);
	}

	Polygon
	create_quad (
		coord x1, coord y1, coord x2, coord y2,
		coord x3, coord y3, coord x4, coord y4,
		bool loop)
	{
		Point points[] = {Point(x1, y1), Point(x2, y2), Point(x3, y3), Point(x4, y4)};
		return create_quads(points, 4, loop);
	}

	Polygon
	create_quad (
		const Point& p1, const Point& p2, const Point& p3, const Point& p4,
		bool loop)
	{
		Point points[] = {p1, p2, p3, p4};
		return create_quads(points, 4, loop);
	}

	Polygon
	create_quads (
		const Point* points, size_t size, bool loop,
		const Color* colors, const Coord3* texcoords)
	{
		Polygon p;
		for (size_t i = 0; i + 3 < size; i += 4)
		{
			p.self->append(Polyline(
				&points[i], 4, loop, true,
				colors    ? &colors[i]    : NULL,
				texcoords ? &texcoords[i] : NULL));
		}
		return p;
	}

	Polygon
	create_quad_strip (
		const Point* points, size_t size,
		const Color* colors, const Coord3* texcoords)
	{
		Polygon p;
		if (size < 4) return p;

		if (size % 2 != 0) --size;
		size_t  in_last = size - 2;
		size_t out_last = size - 1;

		std::vector<Point> points_;
		points_.reserve(size);
		for (size_t i = 0; i <= in_last; i += 2)
			points_.emplace_back(points[i]);
		for (int i = (int) out_last; i >= 1; i -= 2)
			points_.emplace_back(points[i]);

		std::unique_ptr<std::vector<Color>> pcolors_;
		if (colors)
		{
			pcolors_.reset(new decltype(pcolors_)::element_type());
			pcolors_->reserve(size);
			for (size_t i = 0; i <= in_last; i += 2)
				pcolors_->emplace_back(colors[i]);
			for (int i = (int) out_last; i >= 1; i -= 2)
				pcolors_->emplace_back(colors[i]);
		}

		std::unique_ptr<std::vector<Coord3>> ptexcoords_;
		if (texcoords)
		{
			ptexcoords_.reset(new decltype(ptexcoords_)::element_type());
			ptexcoords_->reserve(size);
			for (size_t i = 0; i <= in_last; i += 2)
				ptexcoords_->emplace_back(texcoords[i]);
			for (int i = (int) out_last; i >= 1; i -= 2)
				ptexcoords_->emplace_back(texcoords[i]);
		}

		p.self->append(Polyline(
			&points_[0], points_.size(), true,
			pcolors_    ? &(*pcolors_)[0]    : NULL,
			ptexcoords_ ? &(*ptexcoords_)[0] : NULL));
		for (size_t i = 2; i < in_last; i += 2)
		{
			p.self->append(Polyline(
				&points[i], 2, false,
				colors    ? &colors[i]    : NULL,
				texcoords ? &texcoords[i] : NULL));
		}
		return p;
	}

	Polygon
	create_ellipse (
		coord x, coord y, coord width, coord height,
		const Point& hole_size,
		float angle_from, float angle_to,
		uint nsegment)
	{
		if (width == 0 || height == 0 || angle_from == angle_to)
			return Polygon();

		return Polygon(new EllipseData(
			x, y, width, height, hole_size, angle_from, angle_to, nsegment));
	}

	Polygon
	create_ellipse (
		const Bounds& bounds,
		const Point& hole_size,
		float angle_from, float angle_to,
		uint nsegment)
	{
		return create_ellipse(
			bounds.x, bounds.y, bounds.width, bounds.height,
			hole_size, angle_from, angle_to, nsegment);
	}

	Polygon
	create_ellipse (
		const Point& center, const Point& radius,
		const Point& hole_radius,
		float angle_from, float angle_to,
		uint nsegment)
	{
		return create_ellipse(
			center.x - radius.x, center.y - radius.y,
			radius.x * 2,        radius.y * 2,
			hole_radius * 2, angle_from, angle_to, nsegment);
	}

	static inline const SplineLib::Vec3f&
	to_splinelib (const Point& val)
	{
		return *(const SplineLib::Vec3f*) &val;
	}

	static inline const Point&
	to_rays (const SplineLib::Vec3f& val)
	{
		return *(const Point*) &val;
	}

	enum SplineType {BEZIER, HERMITE, CATMULLROM};

	typedef SplineLib::cSpline3 (*SplineFun) (
		const SplineLib::Vec3f&, const SplineLib::Vec3f&,
		const SplineLib::Vec3f&, const SplineLib::Vec3f&);

	static SplineFun
	get_spline_fun (SplineType type)
	{
		switch (type)
		{
			case BEZIER:     return SplineLib::BezierSpline;
			case HERMITE:    return SplineLib::HermiteSpline;
			case CATMULLROM: return SplineLib::CatmullRomSpline;
			default:
				argument_error(__FILE__, __LINE__, "unknown spline type %d.", type);
		}
	}

	static Polygon
	create_spline (
		SplineType type,
		const Point* points, size_t size, bool loop,
		uint nsegment = 0)
	{
		if (size % 4 != 0)
			argument_error(__FILE__, __LINE__);

		if (nsegment <= 0) nsegment = 16;

		size_t count = size / 4;
		auto spline_fun = get_spline_fun(type);

		std::vector<Point> result;
		result.reserve(nsegment * count);
		for (size_t i = 0; i < count; ++i)
		{
			SplineLib::cSpline3 spline = spline_fun(
				to_splinelib(points[i * 4 + 0]),
				to_splinelib(points[i * 4 + 1]),
				to_splinelib(points[i * 4 + 2]),
				to_splinelib(points[i * 4 + 3]));
			for (uint j = 0; j <= nsegment; ++j)
			{
				float t = (float) j / nsegment;
				result.emplace_back(to_rays(SplineLib::Position(spline, t)));
			}
		}

		return create_line(&result[0], result.size(), loop);
	}

	Polygon
	create_curve (
		coord x1, coord y1, coord x2, coord y2,
		coord x3, coord y3, coord x4, coord y4,
		bool loop, uint nsegment)
	{
		const Point points[] = {
			Point(x1, y1),
			Point(x2, y2),
			Point(x3, y3),
			Point(x4, y4)
		};
		return create_spline(CATMULLROM, points, 4, loop, nsegment);
	}

	Polygon
	create_curve (
		const Point& p1, const Point& p2, const Point& p3, const Point& p4,
		bool loop, uint nsegment)
	{
		const Point points[] = {p1, p2, p3, p4};
		return create_spline(CATMULLROM, points, 4, loop, nsegment);
	}

	Polygon
	create_curve (const Point* points, size_t size, bool loop, uint nsegment)
	{
		return create_spline(CATMULLROM, points, size, loop, nsegment);
	}

	Polygon
	create_bezier (
		coord x1, coord y1, coord x2, coord y2,
		coord x3, coord y3, coord x4, coord y4,
		bool loop, uint nsegment)
	{
		const Point points[] = {
			Point(x1, y1),
			Point(x2, y2),
			Point(x3, y3),
			Point(x4, y4)
		};
		return create_spline(BEZIER, points, 4, loop, nsegment);
	}

	Polygon
	create_bezier (
		const Point& p1, const Point& p2, const Point& p3, const Point& p4,
		bool loop, uint nsegment)
	{
		const Point points[] = {p1, p2, p3, p4};
		return create_spline(BEZIER, points, 4, loop, nsegment);
	}

	Polygon
	create_bezier (const Point* points, size_t size, bool loop, uint nsegment)
	{
		return create_spline(BEZIER, points, size, loop, nsegment);
	}

	void
	Polygon_fill (const Polygon& polygon, Painter* painter, const Color& color)
	{
		if (!painter)
			argument_error(__FILE__, __LINE__);

		if (!color || !polygon || polygon.empty())
			return;

		polygon.self->fill(painter, color);
	}

	void
	Polygon_stroke (const Polygon& polygon, Painter* painter, const Color& color)
	{
		if (!painter)
			argument_error(__FILE__, __LINE__);

		if (!color || !polygon || polygon.empty())
			return;

		polygon.self->stroke(polygon, painter, color);
	}

	bool
	Polygon_triangulate (
		Polygon::TrianglePointList* triangles, const Polygon& polygon)
	{
		return polygon.self->triangulate(triangles);
	}


	Polygon::Polygon ()
	{
	}

	Polygon::Polygon (
		const Point* points, size_t size, bool loop,
		const Color* colors, const Coord3* texcoords)
	{
		if (!points || size <= 0) return;

		self->append(Polyline(points, size, loop, true, colors, texcoords));
	}

	Polygon::Polygon (const Polyline& polyline)
	{
		if (polyline.hole())
			argument_error(__FILE__, __LINE__);

		self->append(polyline);
	}

	Polygon::Polygon (const Polyline* polylines, size_t size)
	{
		if (!polylines || size <= 0)
			return;

		if (polylines[0].hole())
			argument_error(__FILE__, __LINE__);

		for (size_t i = 0; i < size; ++i)
			self->append(polylines[i]);
	}

	Polygon::Polygon (Data* data)
	:	self(data)
	{
	}

	Polygon::~Polygon ()
	{
	}

	bool
	Polygon::expand (
		Polygon* result,
		coord width, CapType cap, JoinType join, coord miter_limit) const
	{
		return expand_polygon(result, *this, width, cap, join, miter_limit);
	}

	Bounds
	Polygon::bounds () const
	{
		return self->bounds();
	}

	size_t
	Polygon::size () const
	{
		return self->polylines.size();
	}

	bool
	Polygon::empty (bool deep) const
	{
		if (deep)
		{
			for (const auto& polyline : self->polylines)
			{
				if (!polyline.empty())
					return false;
			}
		}

		return size() <= 0;
	}

	Polygon::const_iterator
	Polygon::begin () const
	{
		return self->polylines.begin();
	}

	Polygon::const_iterator
	Polygon::end () const
	{
		return self->polylines.end();
	}

	const Polyline&
	Polygon::operator [] (size_t index) const
	{
		return self->polylines[index];
	}

	Polygon::operator bool () const
	{
		if (self->polylines.empty())
			return true;

		for (const auto& polyline : self->polylines)
		{
			if (polyline) return true;
		}

		return false;
	}

	bool
	Polygon::operator ! () const
	{
		return !operator bool();
	}

	bool
	Polygon::triangulate (TrianglePointList* triangles) const
	{
		return self->triangulate(triangles);
	}

	Polygon
	operator + (const Polygon& lhs, const Polyline& rhs)
	{
		std::vector<Polyline> polylines;
		for (const auto& polyline : lhs)
			polylines.emplace_back(polyline);
		polylines.emplace_back(rhs);
		return Polygon(&polylines[0], polylines.size());
	}

	Polygon
	operator + (const Polygon& lhs, const Polygon& rhs)
	{
		std::vector<Polyline> polylines;
		for (const auto& polyline : lhs) polylines.emplace_back(polyline);
		for (const auto& polyline : rhs) polylines.emplace_back(polyline);
		return Polygon(&polylines[0], polylines.size());
	}

	Polygon
	operator - (const Polygon& lhs, const Polygon& rhs)
	{
		if (lhs.self == rhs.self) return Polygon();

		return clip_polygons(lhs, rhs, clip::ctDifference);
	}

	Polygon
	operator & (const Polygon& lhs, const Polygon& rhs)
	{
		if (lhs.self == rhs.self) return lhs;

		return clip_polygons(lhs, rhs, clip::ctIntersection);
	}

	Polygon
	operator | (const Polygon& lhs, const Polygon& rhs)
	{
		if (lhs.self == rhs.self) return lhs;

		return clip_polygons(lhs, rhs, clip::ctUnion);
	}

	Polygon
	operator ^ (const Polygon& lhs, const Polygon& rhs)
	{
		if (lhs.self == rhs.self) return Polygon();

		return clip_polygons(lhs, rhs, clip::ctXor);
	}


}// Rays
