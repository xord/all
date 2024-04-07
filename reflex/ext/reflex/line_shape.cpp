#include "reflex/ruby/shape.h"


#include <rays/ruby/point.h>
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::LineShape)

#define THIS      to<Reflex::LineShape*>(self)

#define CHECK     RUCY_CHECK_OBJ(Reflex::LineShape, self)

#define CALL(fun) RUCY_CALL_SUPER(THIS, fun)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return value(new Reflex::RubyShape<Reflex::LineShape>, klass);
}
RUCY_END

static
RUCY_DEFN(add_point)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "LineShape#add_point", argc, 1, 2, 3);

	THIS->add_point(to<Rays::Point>(argc, argv));
	return self;
}
RUCY_END

static
RUCY_DEFN(add_points)
{
	CHECK;

	if (argc <= 0) return self;

	if (argv[0].is_num())
	{
		if (argc % 2 != 0)
			argument_error(__FILE__, __LINE__);

		for (int i = 0; i < argc; i += 2)
			THIS->add_point(to<coord>(argv[i]), to<coord>(argv[i + 1]));
	}
	else
	{
		for (int i = 0; i < argc; ++i)
			THIS->add_point(to<Rays::Point>(argv[i]));
	}
	return self;
}
RUCY_END

static
RUCY_DEF1(set_loop, loop)
{
	CHECK;
	THIS->set_loop(loop);
	return loop;
}
RUCY_END

static
RUCY_DEF0(get_loop)
{
	CHECK;
	return value(THIS->loop());
}
RUCY_END


static Class cLineShape;

void
Init_reflex_line_shape ()
{
	Module mReflex = define_module("Reflex");

	cLineShape = mReflex.define_class("LineShape", Reflex::shape_class());
	cLineShape.define_alloc_func(alloc);
	cLineShape.define_method("add_point",  add_point);
	cLineShape.define_method("add_points", add_points);
	cLineShape.define_method("loop=", set_loop);
	cLineShape.define_method("loop",  get_loop);
}


namespace Reflex
{


	Class
	line_shape_class ()
	{
		return cLineShape;
	}


}// Reflex
