#include "rays/ruby/polygon.h"


#include <assert.h>
#include "rays/ruby/polyline.h"
#include "defs.h"


RUCY_DEFINE_VALUE_OR_ARRAY_FROM_TO(Rays::Polygon::Line)

#define THIS  to<Rays::Polygon::Line*>(self)

#define CHECK RUCY_CHECK_OBJECT(Rays::Polygon::Line, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::Polygon::Line>(klass);
}
RUCY_END

static
RUCY_DEF3(setup, points, loop, hole)
{
	CHECK;

	std::vector<Rays::Point> array;
	get_line_args(&array, points.size(), points.as_array());
	*THIS = Rays::Polygon::Line(&array[0], array.size(), loop, hole);
}
RUCY_END

static
RUCY_DEF0(hole)
{
	CHECK;
	return value(THIS->hole());
}
RUCY_END


static Class cPolygonLine;

void
Init_rays_polygon_line ()
{
	Module mRays   = define_module("Rays");
	Class cPolygon = mRays.define_class("Polygon");

	cPolygonLine = cPolygon.define_class("Line", Rays::polyline_class());
	cPolygonLine.define_alloc_func(alloc);
	cPolygonLine.define_private_method("setup", setup);
	cPolygonLine.define_method("hole?", hole);
}


namespace Rucy
{


	template <> Rays::Polygon::Line
	value_to<Rays::Polygon::Line> (int argc, const Value* argv, bool convert)
	{
		assert(argc == 0 || (argc > 0 && argv));

		if (convert)
		{
			if (argc <= 0)
				return Rays::Polygon::Line();
			else if (argv->is_num() || argv->is_array())
			{
				std::vector<Rays::Point> points;
				get_line_args(&points, argc, argv);
				return Rays::Polygon::Line(&points[0], points.size());
			}
		}

		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		return value_to<Rays::Polygon::Line&>(*argv, convert);
	}


}// Rucy


namespace Rays
{


	Class
	polygon_line_class ()
	{
		return cPolygonLine;
	}


}// Rays
