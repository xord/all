#include "reflex/ruby/shape.h"


#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(Reflex::EllipseShape)

#define THIS      to<Reflex::EllipseShape*>(self)

#define CHECK     RUCY_CHECK_OBJ(Reflex::EllipseShape, self)

#define CALL(fun) RUCY_CALL_SUPER(THIS, fun)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return value(new Reflex::RubyShape<Reflex::EllipseShape>, klass);
}
RUCY_END

static
RUCY_DEF1(set_angle_from, degree)
{
	CHECK;
	THIS->set_angle_from(to<float>(degree));
	return self;
}
RUCY_END

static
RUCY_DEF0(get_angle_from)
{
	CHECK;
	return value(THIS->angle_from());
}
RUCY_END

static
RUCY_DEF1(set_angle_to, degree)
{
	CHECK;
	THIS->set_angle_to(to<float>(degree));
	return self;
}
RUCY_END

static
RUCY_DEF0(get_angle_to)
{
	CHECK;
	return value(THIS->angle_to());
}
RUCY_END

static
RUCY_DEFN(set_hole_size)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "EllipseShape#set_hole_size", argc, 1, 2, 3);

	THIS->set_hole_size(to<Rays::Point>(argc, argv));
	return value(THIS->hole_size());
}
RUCY_END

static
RUCY_DEF0(get_hole_size)
{
	CHECK;
	return value(THIS->hole_size());
}
RUCY_END

static
RUCY_DEF1(set_nsegment, nsegment)
{
	CHECK;
	THIS->set_nsegment(to<uint>(nsegment));
	return nsegment;
}
RUCY_END

static
RUCY_DEF0(get_nsegment)
{
	CHECK;
	return value(THIS->nsegment());
}
RUCY_END


static Class cEllipseShape;

void
Init_reflex_ellipse_shape ()
{
	Module mReflex = define_module("Reflex");

	cEllipseShape = mReflex.define_class("EllipseShape", Reflex::shape_class());
	cEllipseShape.define_alloc_func(alloc);
	cEllipseShape.define_method("angle_from=", set_angle_from);
	cEllipseShape.define_method("angle_from",  get_angle_from);
	cEllipseShape.define_method("angle_to=",   set_angle_to);
	cEllipseShape.define_method("angle_to",    get_angle_to);
	cEllipseShape.define_method("hole_size=", set_hole_size);
	cEllipseShape.define_method("hole_size",  get_hole_size);
	cEllipseShape.define_method("nsegment=", set_nsegment);
	cEllipseShape.define_method("nsegment",  get_nsegment);
}


namespace Reflex
{


	Class
	ellipse_shape_class ()
	{
		return cEllipseShape;
	}


}// Reflex
