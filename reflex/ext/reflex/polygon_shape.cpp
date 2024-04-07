#include "reflex/ruby/shape.h"


#include <rays/ruby/polygon.h>
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::PolygonShape)

#define THIS      to<Reflex::PolygonShape*>(self)

#define CHECK     RUCY_CHECK_OBJ(Reflex::PolygonShape, self)

#define CALL(fun) RUCY_CALL_SUPER(THIS, fun)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return value(new Reflex::RubyShape<Reflex::PolygonShape>, klass);
}
RUCY_END

static
RUCY_DEF1(set_polygon, polygon)
{
	CHECK;

	THIS->set_polygon(to<Rays::Polygon&>(polygon));
	return polygon;
}
RUCY_END

static
RUCY_DEF0(get_polygon)
{
	CHECK;
	return value(THIS->polygon());
}
RUCY_END


static Class cPolygonShape;

void
Init_reflex_polygon_shape ()
{
	Module mReflex = define_module("Reflex");

	cPolygonShape = mReflex.define_class("PolygonShape", Reflex::shape_class());
	cPolygonShape.define_alloc_func(alloc);
	cPolygonShape.define_method("polygon=", set_polygon);
	cPolygonShape.define_method("polygon",  get_polygon);
}


namespace Reflex
{


	Class
	polygon_shape_class ()
	{
		return cPolygonShape;
	}


}// Reflex
