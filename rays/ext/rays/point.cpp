#include "rays/ruby/point.h"


#include <assert.h>
#include "defs.h"


RUCY_DEFINE_VALUE_OR_ARRAY_FROM_TO(RAYS_EXPORT, Rays::Point)

#define THIS  to<Rays::Point*>(self)

#define CHECK RUCY_CHECK_OBJ(Rays::Point, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::Point>(klass);
}
RUCY_END

static
RUCY_DEFN(initialize)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Point#initialize", argc, 0, 1, 2, 3);

	if (argc >= 1)
		*THIS = to<Rays::Point>(argc, argv);

	return self;
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Rays::Point&>(obj);
	return self;
}
RUCY_END

static
RUCY_DEFN(move_to)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Point#move_to", argc, 1, 2, 3);

	if (argv[0].is_a(Rays::point_class()))
		THIS->move_to(to<Rays::Point&>(argv[0]));
	else
	{
		const Rays::Point& p = *THIS;
		coord x = (argc >= 1 && argv[0]) ? to<coord>(argv[0]) : p.x;
		coord y = (argc >= 2 && argv[1]) ? to<coord>(argv[1]) : p.y;
		coord z = (argc >= 3 && argv[2]) ? to<coord>(argv[2]) : p.z;
		THIS->move_to(x, y, z);
	}

	return self;
}
RUCY_END

static
RUCY_DEFN(move_by)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Point#move_by", argc, 1, 2, 3);

	if (argv[0].is_a(Rays::point_class()))
		THIS->move_by(to<Rays::Point&>(argv[0]));
	else
	{
		coord x = (argc >= 1 && argv[0]) ? to<coord>(argv[0]) : 0;
		coord y = (argc >= 2 && argv[1]) ? to<coord>(argv[1]) : 0;
		coord z = (argc >= 3 && argv[2]) ? to<coord>(argv[2]) : 0;
		THIS->move_by(x, y, z);
	}

	return self;
}
RUCY_END

static
RUCY_DEF1(rotate, degree)
{
	CHECK;
	THIS->rotate(to<float>(degree));
}
RUCY_END

static
RUCY_DEF0(length)
{
	CHECK;
	return value(THIS->length());
}
RUCY_END

static
RUCY_DEF0(normalize)
{
	CHECK;
	THIS->normalize();
	return self;
}
RUCY_END

static
RUCY_DEF0(normal)
{
	CHECK;
	return value(THIS->normal());
}
RUCY_END

static
RUCY_DEF1(set_x, x)
{
	CHECK;
	THIS->x = to<coord>(x);
	return x;
}
RUCY_END

static
RUCY_DEF0(get_x)
{
	CHECK;
	return value(THIS->x);
}
RUCY_END

static
RUCY_DEF1(set_y, y)
{
	CHECK;
	THIS->y = to<coord>(y);
	return y;
}
RUCY_END

static
RUCY_DEF0(get_y)
{
	CHECK;
	return value(THIS->y);
}
RUCY_END

static
RUCY_DEF1(set_z, z)
{
	CHECK;
	THIS->z = to<coord>(z);
	return z;
}
RUCY_END

static
RUCY_DEF0(get_z)
{
	CHECK;
	return value(THIS->z);
}
RUCY_END

static
RUCY_DEF0(negate)
{
	CHECK;
	return value(-*THIS);
}
RUCY_END

static
RUCY_DEFN(add)
{
	CHECK;
	if (argc == 1 && argv->is_num())
		return value(*THIS + to<coord>(*argv));
	else
		return value(*THIS + to<Rays::Point>(argc, argv));
}
RUCY_END

static
RUCY_DEFN(sub)
{
	CHECK;
	if (argc == 1 && argv->is_num())
		return value(*THIS - to<coord>(*argv));
	else
		return value(*THIS - to<Rays::Point>(argc, argv));
}
RUCY_END

static
RUCY_DEFN(mult)
{
	CHECK;
	if (argc == 1 && argv->is_num())
		return value(*THIS * to<coord>(*argv));
	else
		return value(*THIS * to<Rays::Point>(argc, argv));
}
RUCY_END

static
RUCY_DEFN(div)
{
	CHECK;
	if (argc == 1 && argv->is_num())
		return value(*THIS / to<coord>(*argv));
	else
		return value(*THIS / to<Rays::Point>(argc, argv));
}
RUCY_END

static
RUCY_DEF2(set_at, index, value)
{
	CHECK;

	int i = index.as_i();
	if (i < 0 || 2 < i)
		index_error(__FILE__, __LINE__);

	(*THIS)[i] = to<coord>(value);
	return value;
}
RUCY_END

static
RUCY_DEF1(get_at, index)
{
	CHECK;

	int i = index.as_i();
	if (i < 0 || 2 < i)
		index_error(__FILE__, __LINE__);

	return value((*THIS)[i]);
}
RUCY_END

static
RUCY_DEF2(dot, p1, p2)
{
	return value(Rays::dot(to<Rays::Point>(p1), to<Rays::Point>(p2)));
}
RUCY_END

static
RUCY_DEF2(cross, p1, p2)
{
	return value(Rays::cross(to<Rays::Point>(p1), to<Rays::Point>(p2)));
}
RUCY_END


static Class cPoint;

void
Init_rays_point ()
{
	Module mRays = define_module("Rays");

	cPoint = mRays.define_class("Point");
	cPoint.define_alloc_func(alloc);
	cPoint.define_private_method("initialize",      initialize);
	cPoint.define_private_method("initialize_copy", initialize_copy);
	cPoint.define_method("move_to!", move_to);
	cPoint.define_method("move_by!", move_by);
	cPoint.define_method("rotate!",  rotate);
	cPoint.define_method("length", length);
	cPoint.define_method("normalize", normalize);
	cPoint.define_method("normal",    normal);
	cPoint.define_method("x=", set_x);
	cPoint.define_method("x",  get_x);
	cPoint.define_method("y=", set_y);
	cPoint.define_method("y",  get_y);
	cPoint.define_method("z=", set_z);
	cPoint.define_method("z",  get_z);
	cPoint.define_method("-@", negate);
	cPoint.define_method("+", add);
	cPoint.define_method("-", sub);
	cPoint.define_method("*", mult);
	cPoint.define_method("/", div);
	cPoint.define_method("[]=", set_at);
	cPoint.define_method("[]",  get_at);
	cPoint.define_module_function("dot",   dot);
	cPoint.define_module_function("cross", cross);
}


namespace Rucy
{


	template <> RAYS_EXPORT Rays::Point
	value_to<Rays::Point> (int argc, const Value* argv, bool convert)
	{
		if (argc == 1 && argv->is_array())
		{
			argc = argv->size();
			argv = argv->as_array();
		}

		assert(argc == 0 || (argc > 0 && argv));

		if (convert)
		{
			if (argc == 0)
				return Rays::Point();
			else if (argv->is_num())
			{
				switch (argc)
				{
					#define V(i) to<coord>(argv[i])
					case 1: return Rays::Point(V(0));
					case 2: return Rays::Point(V(0), V(1));
					case 3: return Rays::Point(V(0), V(1), V(2));
					#undef V
					default: argument_error(__FILE__, __LINE__);
				}
			}
		}

		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		return value_to<Rays::Point&>(*argv, convert);
	}


}// Rucy


namespace Rays
{


	Class
	point_class ()
	{
		return cPoint;
	}


}// Rays
