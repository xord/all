#include "rays/ruby/polyline.h"


#include <assert.h>
#include <vector>
#include "rays/ruby/color.h"
#include "rays/ruby/point.h"
#include "rays/ruby/bounds.h"
#include "rays/ruby/polygon.h"
#include "defs.h"


RUCY_DEFINE_VALUE_OR_ARRAY_FROM_TO(RAYS_EXPORT, Rays::Polyline)

#define THIS  to<Rays::Polyline*>(self)

#define CHECK RUCY_CHECK_OBJECT(Rays::Polyline, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::Polyline>(klass);
}
RUCY_END

static
RUCY_DEF6(setup, points, loop, fill, colors, texcoords, hole)
{
	CHECK;

	CreateParams params(points, colors, texcoords);
	*THIS = Rays::Polyline(
		params.ppoints(), params.size(), loop, fill,
		params.pcolors(), params.ptexcoords(),
		hole);
}
RUCY_END

static
RUCY_DEFN(expand)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Polyline#expand", argc, 1, 2, 3, 4);

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
RUCY_DEF0(is_loop)
{
	CHECK;
	return value(THIS->loop());
}
RUCY_END

static
RUCY_DEF0(is_fill)
{
	CHECK;
	return value(THIS->fill());
}
RUCY_END

static
RUCY_DEF0(is_hole)
{
	CHECK;
	return value(THIS->hole());
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
RUCY_DEF0(has_points)
{
	CHECK;
	return value(THIS->points() && !THIS->empty());
}
RUCY_END

static
RUCY_DEF0(has_colors)
{
	CHECK;
	return value(THIS->colors() && !THIS->empty());
}
RUCY_END

static
RUCY_DEF0(has_texcoords)
{
	CHECK;
	return value(THIS->texcoords() && !THIS->empty());
}
RUCY_END

static
RUCY_DEF0(each_point)
{
	CHECK;

	Value ret = Qnil;
	for (const auto& point : *THIS)
		ret = rb_yield(value(point));
	return ret;
}
RUCY_END

static
RUCY_DEF0(each_color)
{
	CHECK;

	const Rays::Color* colors = THIS->colors();

	Value ret = Qnil;
	if (colors)
	{
		size_t size = THIS->size();
		for (size_t i = 0; i < size; ++i)
			ret = rb_yield(value(colors[i]));
	}
	return ret;
}
RUCY_END

static
RUCY_DEF0(each_texcoord)
{
	CHECK;

	const Rays::Coord3* texcoords = THIS->texcoords();

	Value ret = Qnil;
	if (texcoords)
	{
		size_t size = THIS->size();
		for (size_t i = 0; i < size; ++i)
			ret = rb_yield(value(*(Rays::Point*) &texcoords[i]));
	}
	return ret;
}
RUCY_END


static Class cPolyline;

void
Init_rays_polyline ()
{
	Module mRays = define_module("Rays");

	cPolyline = mRays.define_class("Polyline");
	cPolyline.define_alloc_func(alloc);
	cPolyline.define_private_method("setup", setup);
	cPolyline.define_method("expand", expand);
	cPolyline.define_method("bounds", bounds);
	cPolyline.define_method("loop?", is_loop);
	cPolyline.define_method("fill?", is_fill);
	cPolyline.define_method("hole?", is_hole);
	cPolyline.define_method("size", size);
	cPolyline.define_method("empty?", is_empty);
	cPolyline.define_method("[]", get_at);
	cPolyline.define_method("points?",    has_points);
	cPolyline.define_method("colors?",    has_colors);
	cPolyline.define_method("texcoords?", has_texcoords);
	cPolyline.define_private_method("each_point!",    each_point);
	cPolyline.define_private_method("each_color!",    each_color);
	cPolyline.define_private_method("each_texcoord!", each_texcoord);
}


namespace Rucy
{


	template <> RAYS_EXPORT Rays::Polyline
	value_to<Rays::Polyline> (int argc, const Value* argv, bool convert)
	{
		assert(argc == 0 || (argc > 0 && argv));

		if (convert)
		{
			if (argc <= 0)
				return Rays::Polyline();
			else if (argv->is_num() || argv->is_array())
			{
				std::vector<Rays::Point> points;
				get_points(&points, argc, argv);
				return Rays::Polyline(&points[0], points.size());
			}
		}

		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		return value_to<Rays::Polyline&>(*argv, convert);
	}


}// Rucy


namespace Rays
{


	Class
	polyline_class ()
	{
		return cPolyline;
	}


}// Rays
