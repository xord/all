#include "rays/ruby/polygon.h"


#include <vector>
#include <functional>
#include "rays/ruby/bounds.h"
#include "rays/ruby/polyline.h"
#include "defs.h"


RUCY_DEFINE_VALUE_OR_ARRAY_FROM_TO(Rays::Polygon)

#define THIS  to<Rays::Polygon*>(self)

#define CHECK RUCY_CHECK_OBJECT(Rays::Polygon, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::Polygon>(klass);
}
RUCY_END

static
RUCY_DEF4(setup, args, loop, colors, texcoords)
{
	CHECK;

	if (args[0].is_kind_of(Rays::polyline_class()))
		*THIS = to<Rays::Polygon>(args.size(), args.as_array());
	else
	{
		CreateParams params(args, colors, texcoords);
		*THIS = Rays::Polygon(
			params.ppoints(), params.size(), loop,
			params.pcolors(), params.ptexcoords());
	}
}
RUCY_END

static
RUCY_DEFN(expand)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Polygon#expand", argc, 1, 2, 3, 4);

	coord width         =             to<coord>         (argv[0]);
	Rays::CapType cap   = argc >= 2 ? to<Rays::CapType> (argv[1]) : Rays::CAP_DEFAULT;
	Rays::JoinType join = argc >= 3 ? to<Rays::JoinType>(argv[2]) : Rays::JOIN_DEFAULT;
	coord ml            = argc >= 4 ? to<coord>         (argv[3]) : (coord) Rays::JOIN_DEFAULT_MITER_LIMIT;

	Rays::Polygon polygon;
	THIS->expand(&polygon, width, cap, join, ml);
	return value(polygon);
}
RUCY_END

static
RUCY_DEF0(bounds)
{
	CHECK;
	return value(THIS->bounds());
}
RUCY_END

static
RUCY_DEF0(size)
{
	CHECK;
	return value(THIS->size());
}
RUCY_END

static
RUCY_DEF0(is_empty)
{
	CHECK;
	return value(THIS->empty());
}
RUCY_END

static
RUCY_DEF1(get_at, index)
{
	CHECK;

	int size = (int) THIS->size();
	int i    = to<int>(index);
	if (i < 0) i += size;

	if (i < 0 || size <= i)
		index_error(__FILE__, __LINE__);

	return value((*THIS)[i]);
}
RUCY_END

static
RUCY_DEF0(each)
{
	CHECK;

	Value ret = Qnil;
	for (const auto& polyline : *THIS)
		ret = rb_yield(value(polyline));
	return ret;
}
RUCY_END

template <typename T>
static inline void
each_poly (const Value& value, auto fun)
{
	int size           = value.size();
	const Value* array = value.as_array();

	for (int i = 0; i < size; ++i)
		fun(to<T&>(array[i]));
}

static
RUCY_DEF1(op_add, obj)
{
	CHECK;

	if (obj.is_kind_of(Rays::polyline_class()))
		return value(*THIS + to<Rays::Polyline&>(obj));

	if (obj.is_kind_of(Rays::polygon_class()))
		return value(*THIS + to<Rays::Polygon&>(obj));

	if (!obj.is_array())
		argument_error(__FILE__, __LINE__);

	if (obj.empty()) return self;

	std::vector<Rays::Polyline> polylines;
	for (const auto& polyline : to<Rays::Polygon&>(self))
		polylines.emplace_back(polyline);

	if (obj[0].is_kind_of(Rays::polyline_class()))
	{
		each_poly<Rays::Polyline>(obj, [&](const auto& polyline)
		{
			polylines.emplace_back(polyline);
		});
	}
	else
	{
		each_poly<Rays::Polygon>(obj, [&](const auto& polygon)
		{
			for (const auto& polyline : polygon)
				polylines.emplace_back(polyline);
		});
	}

	return value(Rays::Polygon(&polylines[0], polylines.size()));
}
RUCY_END

static
RUCY_DEF1(op_sub, obj)
{
	CHECK;

	if (obj.is_array())
	{
		Rays::Polygon result = *THIS;
		each_poly<Rays::Polygon>(obj, [&](const auto& polygon)
		{
			result = result - polygon;
		});
		return value(result);
	}
	else
		return value(*THIS - to<Rays::Polygon&>(obj));
}
RUCY_END

static
RUCY_DEF1(op_and, obj)
{
	CHECK;

	if (obj.is_array())
	{
		Rays::Polygon result = *THIS;
		each_poly<Rays::Polygon>(obj, [&](const auto& polygon)
		{
			result = result & polygon;
		});
		return value(result);
	}
	else
		return value(*THIS & to<Rays::Polygon&>(obj));
}
RUCY_END

static
RUCY_DEF1(op_or, obj)
{
	CHECK;

	if (obj.is_array())
	{
		Rays::Polygon result = *THIS;
		each_poly<Rays::Polygon>(obj, [&](const auto& polygon)
		{
			result = result | polygon;
		});
		return value(result);
	}
	else
		return value(*THIS | to<Rays::Polygon&>(obj));
}
RUCY_END

static
RUCY_DEF1(op_xor, obj)
{
	CHECK;

	if (obj.is_array())
	{
		Rays::Polygon result = *THIS;
		each_poly<Rays::Polygon>(obj, [&](const auto& polygon)
		{
			result = result ^ polygon;
		});
		return value(result);
	}
	else
		return value(*THIS ^ to<Rays::Polygon&>(obj));
}
RUCY_END

static
RUCY_DEF1(create_points, points)
{
	CreateParams params(points, nil(), nil());
	return value(Rays::create_points(params.ppoints(), params.size()));
}
RUCY_END

static
RUCY_DEF2(create_line, points, loop)
{
	CreateParams params(points, nil(), nil());
	return value(Rays::create_line(params.ppoints(), params.size(), loop));
}
RUCY_END

static
RUCY_DEF1(create_lines, points)
{
	CreateParams params(points, nil(), nil());
	return value(Rays::create_lines(params.ppoints(), params.size()));
}
RUCY_END

static
RUCY_DEF4(create_triangles, points, loop, colors, texcoords)
{
	CreateParams params(points, colors, texcoords);
	return value(Rays::create_triangles(
		params.ppoints(), params.size(), loop,
		params.pcolors(), params.ptexcoords()));
}
RUCY_END

static
RUCY_DEF3(create_triangle_strip, points, colors, texcoords)
{
	CreateParams params(points, colors, texcoords);
	return value(Rays::create_triangle_strip(
		params.ppoints(), params.size(),
		params.pcolors(), params.ptexcoords()));
}
RUCY_END

static
RUCY_DEF3(create_triangle_fan, points, colors, texcoords)
{
	CreateParams params(points, colors, texcoords);
	return value(Rays::create_triangle_fan(
		params.ppoints(), params.size(),
		params.pcolors(), params.ptexcoords()));
}
RUCY_END

static
RUCY_DEF7(create_rect,
	args, round, lefttop, righttop, leftbottom, rightbottom, nsegment)
{
	coord x, y, w, h, lt, rt, lb, rb;
	uint nseg;
	get_rect_args(
		&x, &y, &w, &h, &lt, &rt, &lb, &rb, &nseg,
		args.size(), args.as_array(),
		round, lefttop, righttop, leftbottom, rightbottom, nsegment);

	return value(Rays::create_rect(x, y, w, h, lt, rt, lb, rb, nseg));
}
RUCY_END

static
RUCY_DEF4(create_quads, points, loop, colors, texcoords)
{
	CreateParams params(points, colors, texcoords);
	return value(Rays::create_quads(
		params.ppoints(), params.size(), loop,
		params.pcolors(), params.ptexcoords()));
}
RUCY_END

static
RUCY_DEF3(create_quad_strip, points, colors, texcoords)
{
	CreateParams params(points, colors, texcoords);
	return value(Rays::create_quad_strip(
		params.ppoints(), params.size(),
		params.pcolors(), params.ptexcoords()));
}
RUCY_END

static
RUCY_DEF7(create_ellipse,
	args, center, radius, hole, angle_from, angle_to, nsegment)
{
	coord x, y, w, h;
	Rays::Point hole_size;
	float from, to_;
	uint nseg;
	get_ellipse_args(
		&x, &y, &w, &h, &hole_size, &from, &to_, &nseg,
		args.size(), args.as_array(),
		center, radius, hole, angle_from, angle_to, nsegment);

	return value(Rays::create_ellipse(x, y, w, h, hole_size, from, to_, nseg));
}
RUCY_END

static
RUCY_DEF3(create_curve, points, loop, nsegment)
{
	CreateParams params(points, nil(), nil());
	uint nseg = nsegment ? 0 : to<uint>(nsegment);
	return value(Rays::create_curve(params.ppoints(), params.size(), loop, nseg));
}
RUCY_END

static
RUCY_DEF3(create_bezier, points, loop, nsegment)
{
	CreateParams params(points, nil(), nil());
	uint nseg = nsegment ? 0 : to<uint>(nsegment);
	return value(Rays::create_bezier(params.ppoints(), params.size(), loop, nseg));
}
RUCY_END


static Class cPolygon;

void
Init_rays_polygon ()
{
	Module mRays = define_module("Rays");

	cPolygon = mRays.define_class("Polygon");
	cPolygon.define_alloc_func(alloc);
	cPolygon.define_private_method("setup", setup);
	cPolygon.define_method("expand", expand);
	cPolygon.define_method("bounds", bounds);
	cPolygon.define_method("size",   size);
	cPolygon.define_method("empty?", is_empty);
	cPolygon.define_method("[]", get_at);
	cPolygon.define_method("each", each);
	cPolygon.define_method("+", op_add);
	cPolygon.define_method("-", op_sub);
	cPolygon.define_method("&", op_and);
	cPolygon.define_method("|", op_or);
	cPolygon.define_method("^", op_xor);
	cPolygon.define_singleton_method("points!",         create_points);
	cPolygon.define_singleton_method("line!",           create_line);
	cPolygon.define_singleton_method("lines!",          create_lines);
	cPolygon.define_singleton_method("triangles!",      create_triangles);
	cPolygon.define_singleton_method("triangle_strip!", create_triangle_strip);
	cPolygon.define_singleton_method("triangle_fan!",   create_triangle_fan);
	cPolygon.define_singleton_method("rect!",           create_rect);
	cPolygon.define_singleton_method("quads!",          create_quads);
	cPolygon.define_singleton_method("quad_strip!",     create_quad_strip);
	cPolygon.define_singleton_method("ellipse!",        create_ellipse);
	cPolygon.define_singleton_method("curve!",          create_curve);
	cPolygon.define_singleton_method("bezier!",         create_bezier);
}


namespace Rucy
{


	template <> Rays::Polygon
	value_to<Rays::Polygon> (int argc, const Value* argv, bool convert)
	{
		if (convert)
		{
			if (argc <= 0)
				return Rays::Polygon();
			else if (argv->is_kind_of(Rays::polyline_class()))
			{
				if (argc == 1)
					return Rays::Polygon(to<Rays::Polyline&>(*argv));
				else
				{
					std::vector<Rays::Polyline> polylines;
					polylines.reserve(argc);
					for (int i = 0; i < argc; ++i)
						polylines.emplace_back(to<Rays::Polyline&>(argv[i]));
					return Rays::Polygon(&polylines[0], polylines.size());
				}
			}
			else if (argv->is_num() || argv->is_array())
			{
				std::vector<Rays::Point> points;
				get_points(&points, argc, argv);
				return Rays::Polygon(&points[0], points.size());
			}
		}

		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		return value_to<Rays::Polygon&>(*argv, convert);
	}


}// Rucy


namespace Rays
{


	Class
	polygon_class ()
	{
		return cPolygon;
	}


}// Rays
