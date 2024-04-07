#include "reflex/ruby/shape.h"


#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::RectShape)

#define THIS      to<Reflex::RectShape*>(self)

#define CHECK     RUCY_CHECK_OBJ(Reflex::RectShape, self)

#define CALL(fun) RUCY_CALL_SUPER(THIS, fun)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return value(new Reflex::RubyShape<Reflex::RectShape>, klass);
}
RUCY_END

static
RUCY_DEFN(set_round)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "RectShape#set_round", argc, 1, 4);

	if (argc == 1)
		THIS->set_round(to<float>(argv[0]));
	else
	{
		THIS->set_round(
			to<float>(argv[0]), to<float>(argv[1]),
			to<float>(argv[2]), to<float>(argv[3]));
	}
	return self;
}
RUCY_END

static
RUCY_DEF0(get_round)
{
	CHECK;
	return array(
		value(THIS->round_left_top()),
		value(THIS->round_right_top()),
		value(THIS->round_left_bottom()),
		value(THIS->round_right_bottom()));
}
RUCY_END

static
RUCY_DEF1(set_round_left_top, round)
{
	CHECK;
	THIS->set_round_left_top(to<coord>(round));
	return round;
}
RUCY_END

static
RUCY_DEF0(get_round_left_top)
{
	CHECK;
	return value(THIS->round_left_top());
}
RUCY_END

static
RUCY_DEF1(set_round_right_top, round)
{
	CHECK;
	THIS->set_round_right_top(to<coord>(round));
	return round;
}
RUCY_END

static
RUCY_DEF0(get_round_right_top)
{
	CHECK;
	return value(THIS->round_right_top());
}
RUCY_END

static
RUCY_DEF1(set_round_left_bottom, round)
{
	CHECK;
	THIS->set_round_left_bottom(to<coord>(round));
	return round;
}
RUCY_END

static
RUCY_DEF0(get_round_left_bottom)
{
	CHECK;
	return value(THIS->round_left_bottom());
}
RUCY_END

static
RUCY_DEF1(set_round_right_bottom, round)
{
	CHECK;
	THIS->set_round_right_bottom(to<coord>(round));
	return round;
}
RUCY_END

static
RUCY_DEF0(get_round_right_bottom)
{
	CHECK;
	return value(THIS->round_right_bottom());
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


static Class cRectShape;

void
Init_reflex_rect_shape ()
{
	Module mReflex = define_module("Reflex");

	cRectShape = mReflex.define_class("RectShape", Reflex::shape_class());
	cRectShape.define_alloc_func(alloc);
	cRectShape.define_method("round=",              set_round);
	cRectShape.define_method("round",               get_round);
	cRectShape.define_method("round_left_top=",     set_round_left_top);
	cRectShape.define_method("round_left_top",      get_round_left_top);
	cRectShape.define_method("round_right_top=",    set_round_right_top);
	cRectShape.define_method("round_right_top",     get_round_right_top);
	cRectShape.define_method("round_left_bottom=",  set_round_left_bottom);
	cRectShape.define_method("round_left_bottom",   get_round_left_bottom);
	cRectShape.define_method("round_right_bottom=", set_round_right_bottom);
	cRectShape.define_method("round_right_bottom",  get_round_right_bottom);
	cRectShape.define_method("nsegment=", set_nsegment);
	cRectShape.define_method("nsegment",  get_nsegment);
}


namespace Reflex
{


	Class
	rect_shape_class ()
	{
		return cRectShape;
	}


}// Reflex
