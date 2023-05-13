#include "polygon.h"


#include <math.h>
#include <assert.h>
#include <utility>
#include <poly2tri.h>
#include <Splines.h>
#include <xot/util.h>
#include "rays/color.h"
#include "rays/exception.h"
#include "rays/debug.h"
#include "polyline.h"
#include "painter.h"


namespace clip = ClipperLib;


namespace Rays
{


	static inline p2t::Point
	to_poly2tri (const Point& point)
	{
		return p2t::Point(point.x, point.y);
	}

	static inline Point
	from_poly2tri (const p2t::Point& point)
	{
		return Point(point.x, point.y);
	}


	struct Polygon::Data
	{

		LineList lines;

		virtual ~Data ()
		{
		}

		void append (const Polyline& polyline, bool hole = false)
		{
			if (polyline.empty())
				return;

			lines.emplace_back(Line(polyline, hole));
		}

		void append (const Line& line)
		{
			if (line.empty())
				return;

			lines.emplace_back(line);
		}

		bool triangulate (TrianglePointList* triangles) const
		{
			assert(triangles);

			triangles->clear();

			if (!can_triangulate())
				return false;

			size_t npoint = count_points();
			if (npoint <= 0)
				return true;

			std::unique_ptr<p2t::CDT> cdt;
			std::vector<p2t::Point> points;
			std::vector<p2t::Point*> pointers;

			points.reserve(npoint);
			for (const auto& line : lines)
			{
				pointers.clear();
				pointers.reserve(line.size());
				for (const auto& point : line)
				{
					points.emplace_back(to_poly2tri(point));
					pointers.emplace_back(&points.back());
				}

				if (!line.hole())
				{
					if (cdt) triangulate(triangles, cdt.get());
					cdt.reset(new p2t::CDT(pointers));
				}
				else if (cdt)
					cdt->AddHole(pointers);
			}

			if (cdt) triangulate(triangles, cdt.get());

			return true;
		}

		virtual void fill (Painter* painter, const Color& color) const = 0;

		virtual void stroke (
			const Polygon& polygon, Painter* painter, const Color& color) const
		{
			assert(painter && color);

			coord stroke_width = painter->stroke_width();
			if (stroke_width > 0)
				stroke_with_width(polygon, painter, color, stroke_width);
			else
				stroke_without_width(painter, color);
		}

		private:

			bool can_triangulate () const
			{
				for (const auto& line : lines)
				{
					if (line.loop() && !line.hole() && !line.empty())
						return true;
				}
				return false;
			}

			size_t count_points () const
			{
				size_t count = 0;
				for (const auto& line : lines)
					count += line.size();
				return count;
			}

			void triangulate (TrianglePointList* triangles, p2t::CDT* cdt) const
			{
				assert(triangles && cdt);

				cdt->Triangulate();

				for (auto* triangle : cdt->GetTriangles())
				{
					for (int i = 0; i < 3; ++i)
						triangles->emplace_back(from_poly2tri(*triangle->GetPoint(i)));
				}
			}

			void stroke_with_width (
				const Polygon& polygon, Painter* painter,
				const Color& color, coord stroke_width) const
			{
				assert(painter && color && stroke_width > 0);

				if (!polygon || polygon.empty()) return;

				CapType cap   = painter->stroke_cap();
				JoinType join = painter->stroke_join();
				coord ml      = painter->miter_limit();

				bool has_loop = false;
				for (const auto& polyline : polygon)
				{
					if (!polyline || polyline.empty())
						continue;

					if (polyline.loop())
					{
						has_loop = true;
						continue;
					}

					Polygon stroke;
					if (!polyline.expand(&stroke, stroke_width / 2, cap, join, ml))
						continue;

					Polygon_fill(stroke, painter, color);
				}

				if (has_loop)
				{
					Polygon hole;
					if (polygon.expand(&hole, -stroke_width, cap, join, ml))
						Polygon_fill(polygon - hole, painter, color);
				}
			}

			void stroke_without_width (Painter* painter, const Color& color) const
			{
				assert(painter && color);

				for (const auto& line : lines)
				{
					Painter_draw_polygon(
						painter, line.loop() ? GL_LINE_LOOP : GL_LINE_STRIP, color,
						&line[0], line.size());
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
	get_nsegment (
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
		for (const auto& line : polygon)
		{
			if (!line) continue;

			Polyline_get_path(&path, line, line.hole());
			if (path.empty()) continue;

			clipper->AddPath(path, type, line.loop());
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
		CapType cap, JoinType join, bool hole, bool fill)
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
		for (const auto& line : polygon.self->lines)
		{
			added |= add_polyline_to_offsetter(
				offsetter, line, cap, join, line.hole(), true);
		}
		return added;
	}

	static bool
	append_outline (Polygon* polygon, const clip::PolyNode& node)
	{
		assert(polygon);

		if (node.Contour.empty() || node.IsHole())
			return false;

		Polyline polyline;
		Polyline_create(&polyline, node.Contour, !node.IsOpen(), false);
		if (!polyline)
			return false;

		polygon->self->append(polyline, false);
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

			Polyline polyline;
			Polyline_create(&polyline, child->Contour, !child->IsOpen(), true);
			if (!polyline)
				continue;

			polygon->self->append(polyline, true);
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


	struct PolygonData : public Polygon::Data
	{

		mutable Polygon::TrianglePointList triangles;

		void fill (Painter* painter, const Color& color) const
		{
			if (triangles.empty())
			{
				if (!triangulate(&triangles))
					return;
			}

			Painter_draw_polygon(
				painter, GL_TRIANGLES, color, &triangles[0], triangles.size());
		}

	};// PolygonData


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
				setup_rect(x, y, width, height, nsegment);
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
			if (lines.size() != 1)
				invalid_state_error(__FILE__, __LINE__);

			const auto& outline = lines[0];
			Painter_draw_polygon(
				painter, GL_TRIANGLE_FAN, color, &outline[0], outline.size());
		}

		private:

			struct RoundedCorner
			{
				coord x, y, offset_sign_x, offset_sign_y, round;
			};

			void setup_rect (
				coord x, coord y, coord width, coord height,
				uint nsegment)
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

				nsegment = get_nsegment(nsegment, 1, 0, 90);

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


	struct EllipseData : public PolygonData
	{

		typedef PolygonData Super;

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
			if (lines.size() <= 0)
				invalid_state_error(__FILE__, __LINE__);

			if (mode == 0)
			{
				Super::fill(painter, color);
				return;
			}

			if (lines.size() >= 2)
				invalid_state_error(__FILE__, __LINE__);

			const auto& outline = lines[0];
			Painter_draw_polygon(painter, mode, color, &outline[0], outline.size());
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

				nsegment = get_nsegment(nsegment, 3, 0, 360);

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
					append(Polyline(&points[0], points.size(), true), true);
				}
			}

			void setup_arc (
				coord x, coord y, coord width, coord height,
				const Point& hole_size, float angle_from, float angle_to,
				uint nsegment)
			{
				assert(width != 0 && height != 0 && angle_from != angle_to);

				nsegment = get_nsegment(nsegment, 3, angle_from, angle_to);

				bool has_hole     = hole_size != 0;
				float radian_from = Xot::deg2rad(angle_from);
				float radian_to   = Xot::deg2rad(angle_to);
				uint npoint       = nsegment + 1;

				std::vector<Point> points;
				points.reserve(has_hole ? npoint * 2 : npoint + 1);

				if (!has_hole)
				{
					points.emplace_back(Point(x + width / 2, y + height / 2));
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
		return Polygon(points, size, loop);
	}

	Polygon
	create_line (const Polyline& polyline)
	{
		return Polygon(polyline);
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
	create_rect(const Bounds& bounds, coord round, uint nsegment)
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
		uint nsegment = 16)
	{
		if (size % 4 != 0)
			argument_error(__FILE__, __LINE__);

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
		bool loop)
	{
		const Point points[] = {
			Point(x1, y1),
			Point(x2, y2),
			Point(x3, y3),
			Point(x4, y4)
		};
		return create_spline(CATMULLROM, points, 4, loop);
	}

	Polygon
	create_curve (
		const Point& p1, const Point& p2, const Point& p3, const Point& p4,
		bool loop)
	{
		const Point points[] = {p1, p2, p3, p4};
		return create_spline(CATMULLROM, points, 4, loop);
	}

	Polygon
	create_curve (const Point* points, size_t size, bool loop)
	{
		return create_spline(CATMULLROM, points, size, loop);
	}

	Polygon
	create_bezier (
		coord x1, coord y1, coord x2, coord y2,
		coord x3, coord y3, coord x4, coord y4,
		bool loop)
	{
		const Point points[] = {
			Point(x1, y1),
			Point(x2, y2),
			Point(x3, y3),
			Point(x4, y4)
		};
		return create_spline(BEZIER, points, 4, loop);
	}

	Polygon
	create_bezier (
		const Point& p1, const Point& p2, const Point& p3, const Point& p4,
		bool loop)
	{
		const Point points[] = {p1, p2, p3, p4};
		return create_spline(BEZIER, points, 4, loop);
	}

	Polygon
	create_bezier (const Point* points, size_t size, bool loop)
	{
		return create_spline(BEZIER, points, size, loop);
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
	:	self(new PolygonData())
	{
	}

	Polygon::Polygon (const Point* points, size_t size, bool loop)
	:	self(new PolygonData())
	{
		if (!points || size <= 0) return;

		self->append(Polyline(points, size, loop));
	}

	Polygon::Polygon (const Polyline& polyline)
	:	self(new PolygonData())
	{
		self->append(polyline);
	}

	Polygon::Polygon (const Line* lines, size_t size)
	:	self(new PolygonData())
	{
		if (!lines || size <= 0) return;

		for (size_t i = 0; i < size; ++i)
			self->append(lines[i]);
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
		if (empty()) return Bounds(-1, -1, -1);

		Bounds b(self->lines[0][0], 0);
		for (const auto& line : *this)
		{
			for (const auto& point : line)
				b |= point;
		}
		return b;
	}

	size_t
	Polygon::size () const
	{
		return self->lines.size();
	}

	bool
	Polygon::empty (bool deep) const
	{
		if (deep)
		{
			for (const auto& line : self->lines)
			{
				if (!line.empty())
					return false;
			}
		}

		return size() <= 0;
	}

	Polygon::const_iterator
	Polygon::begin () const
	{
		return self->lines.begin();
	}

	Polygon::const_iterator
	Polygon::end () const
	{
		return self->lines.end();
	}

	const Polygon::Line&
	Polygon::operator [] (size_t index) const
	{
		return self->lines[index];
	}

	Polygon::operator bool () const
	{
		if (self->lines.empty())
			return true;

		for (const auto& line : self->lines)
		{
			if (line) return true;
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
	operator + (const Polygon& lhs, const Polygon& rhs)
	{
		return lhs | rhs;
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


	Polygon::Line::Line ()
	:	Super(), hole_(false)
	{
	}

	Polygon::Line::Line (const Point* points, size_t size, bool loop, bool hole)
	:	Super(points, size, loop), hole_(hole)
	{
		if (!*this)
			argument_error(__FILE__, __LINE__);
	}

	Polygon::Line::Line (const Polyline& polyline, bool hole)
	:	Super(polyline), hole_(hole)
	{
		if (!*this)
			argument_error(__FILE__, __LINE__);
	}

	bool
	Polygon::Line::hole () const
	{
		return hole_;
	}

	Polygon::Line::operator bool () const
	{
		if (!Super::operator bool())
			return false;

		return loop() || !hole();
	}

	bool
	Polygon::Line::operator ! () const
	{
		return !operator bool();
	}


}// Rays
