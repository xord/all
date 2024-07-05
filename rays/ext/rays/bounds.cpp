#include "rays/ruby/bounds.h"


#include <assert.h>
#include "rays/ruby/point.h"
#include "defs.h"


RUCY_DEFINE_VALUE_OR_ARRAY_FROM_TO(RAYS_EXPORT, Rays::Bounds)

#define THIS  to<Rays::Bounds*>(self)

#define CHECK RUCY_CHECK_OBJ(Rays::Bounds, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::Bounds>(klass);
}
RUCY_END

static
RUCY_DEFN(initialize)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Bounds#initialize", argc, 0, 1, 2, 3, 4, 6);

	if (argc >= 1)
		*THIS = to<Rays::Bounds>(argc, argv);

	return self;
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;

	*THIS = to<Rays::Bounds&>(obj);
	return self;
}
RUCY_END

static
RUCY_DEFN(intersect)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Bounds#intersect?", argc, 1, 2);

	const Rays::Bounds& bounds = to<Rays::Bounds&>(argv[0]);
	int dimension              = argc >= 2 ? to<int>(argv[1]) : 2;

	return value(THIS->is_intersect(bounds, dimension));
}
RUCY_END

static
RUCY_DEFN(include)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Bounds#include?", argc, 1, 2);

	const Rays::Point& point = to<Rays::Point&>(argv[0]);
	int dimension            = argc >= 2 ? to<int>(argv[1]) : 2;

	return value(THIS->is_include(point, dimension));
}
RUCY_END

static
RUCY_DEFN(move_to)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Bounds#move_to", argc, 1, 2, 3);

	if (argv[0].is_kind_of(Rays::point_class()))
		THIS->move_to(to<Rays::Point&>(argv[0]));
	else
	{
		if (argv[0].is_array())
		{
			argc = argv[0].size();
			argv = argv[0].as_array();
		}

		const Rays::Point& p = THIS->position();
		coord x =               argv[0]  ? to<coord>(argv[0]) : p.x;
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
	check_arg_count(__FILE__, __LINE__, "Bounds#move_by", argc, 1, 2, 3);

	if (argv[0].is_kind_of(Rays::point_class()))
		THIS->move_by(to<Rays::Point&>(argv[0]));
	else
	{
		if (argv[0].is_array())
		{
			argc = argv[0].size();
			argv = argv[0].as_array();
		}

		coord x =               argv[0]  ? to<coord>(argv[0]) : 0;
		coord y = (argc >= 2 && argv[1]) ? to<coord>(argv[1]) : 0;
		coord z = (argc >= 3 && argv[2]) ? to<coord>(argv[2]) : 0;
		THIS->move_by(x, y, z);
	}

	return self;
}
RUCY_END

static
RUCY_DEFN(resize_to)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Bounds#resize_to", argc, 1, 2, 3);

	if (argv[0].is_kind_of(Rays::point_class()))
		THIS->resize_to(to<Rays::Point&>(argv[0]));
	else
	{
		if (argv[0].is_array())
		{
			argc = argv[0].size();
			argv = argv[0].as_array();
		}

		const Rays::Point& p = THIS->size();
		coord x =               argv[0]  ? to<coord>(argv[0]) : p.x;
		coord y = (argc >= 2 && argv[1]) ? to<coord>(argv[1]) : p.y;
		coord z = (argc >= 3 && argv[2]) ? to<coord>(argv[2]) : p.z;
		THIS->resize_to(x, y, z);
	}

	return self;
}
RUCY_END

static
RUCY_DEFN(resize_by)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Bounds#resize_by", argc, 1, 2, 3);

	if (argv[0].is_kind_of(Rays::point_class()))
		THIS->resize_by(to<Rays::Point&>(argv[0]));
	else
	{
		if (argv[0].is_array())
		{
			argc = argv[0].size();
			argv = argv[0].as_array();
		}

		coord x =               argv[0]  ? to<coord>(argv[0]) : 0;
		coord y = (argc >= 2 && argv[1]) ? to<coord>(argv[1]) : 0;
		coord z = (argc >= 3 && argv[2]) ? to<coord>(argv[2]) : 0;
		THIS->resize_by(x, y, z);
	}

	return self;
}
RUCY_END

static
RUCY_DEFN(inset_by)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Bounds#inset_by", argc, 1, 2, 3);

	if (argv[0].is_kind_of(Rays::point_class()))
		THIS->inset_by(to<Rays::Point&>(argv[0]));
	else
	{
		if (argv[0].is_array())
		{
			argc = argv[0].size();
			argv = argv[0].as_array();
		}

		coord x =               argv[0]  ? to<coord>(argv[0]) : 0;
		coord y = (argc >= 2 && argv[1]) ? to<coord>(argv[1]) : 0;
		coord z = (argc >= 3 && argv[2]) ? to<coord>(argv[2]) : 0;
		THIS->inset_by(x, y, z);
	}

	return self;
}
RUCY_END

static
RUCY_DEF0(is_valid)
{
	CHECK;

	return value(THIS->operator bool());
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
RUCY_DEF1(set_width, width)
{
	CHECK;

	THIS->width = to<coord>(width);
	return width;
}
RUCY_END

static
RUCY_DEF0(get_width)
{
	CHECK;

	return value(THIS->width);
}
RUCY_END

static
RUCY_DEF1(set_height, height)
{
	CHECK;

	THIS->height = to<coord>(height);
	return height;
}
RUCY_END

static
RUCY_DEF0(get_height)
{
	CHECK;

	return value(THIS->height);
}
RUCY_END

static
RUCY_DEF1(set_depth, depth)
{
	CHECK;

	THIS->depth = to<coord>(depth);
	return depth;
}
RUCY_END

static
RUCY_DEF0(get_depth)
{
	CHECK;

	return value(THIS->depth);
}
RUCY_END

static
RUCY_DEF1(set_left, left)
{
	CHECK;

	THIS->set_left(to<coord>(left));
	return left;
}
RUCY_END

static
RUCY_DEF0(get_left)
{
	CHECK;

	return value(THIS->left());
}
RUCY_END

static
RUCY_DEF1(set_right, right)
{
	CHECK;

	THIS->set_right(to<coord>(right));
	return right;
}
RUCY_END

static
RUCY_DEF0(get_right)
{
	CHECK;

	return value(THIS->right());
}
RUCY_END

static
RUCY_DEF1(set_top, top)
{
	CHECK;

	THIS->set_top(to<coord>(top));
	return top;
}
RUCY_END

static
RUCY_DEF0(get_top)
{
	CHECK;

	return value(THIS->top());
}
RUCY_END

static
RUCY_DEF1(set_bottom, bottom)
{
	CHECK;

	THIS->set_bottom(to<coord>(bottom));
	return bottom;
}
RUCY_END

static
RUCY_DEF0(get_bottom)
{
	CHECK;

	return value(THIS->bottom());
}
RUCY_END

static
RUCY_DEF1(set_back, back)
{
	CHECK;

	THIS->set_back(to<coord>(back));
	return back;
}
RUCY_END

static
RUCY_DEF0(get_back)
{
	CHECK;

	return value(THIS->back());
}
RUCY_END

static
RUCY_DEF1(set_front, front)
{
	CHECK;

	THIS->set_front(to<coord>(front));
	return front;
}
RUCY_END

static
RUCY_DEF0(get_front)
{
	CHECK;

	return value(THIS->front());
}
RUCY_END

static
RUCY_DEFN(set_position)
{
	CHECK;

	THIS->set_position(to<Rays::Point>(argc, argv));
	return value(THIS->position());
}
RUCY_END

static
RUCY_DEF0(get_position)
{
	CHECK;

	return value(THIS->position());
}
RUCY_END

static
RUCY_DEFN(set_size)
{
	CHECK;

	THIS->set_size(to<Rays::Point>(argc, argv));
	return value(THIS->size());
}
RUCY_END

static
RUCY_DEF0(get_size)
{
	CHECK;

	return value(THIS->size());
}
RUCY_END

static
RUCY_DEFN(set_center)
{
	CHECK;

	THIS->set_center(to<Rays::Point>(argc, argv));
	return value(THIS->center());
}
RUCY_END

static
RUCY_DEF0(get_center)
{
	CHECK;

	return value(THIS->center());
}
RUCY_END

static
RUCY_DEF2(set_at, index, value)
{
	CHECK;

	int i = index.as_i();
	if (i < 0 || 1 < i)
		index_error(__FILE__, __LINE__);

	(*THIS)[i] = to<Rays::Point&>(value);
	return value;
}
RUCY_END

static
RUCY_DEF1(get_at, index)
{
	CHECK;

	int i = index.as_i();
	if (i < 0 || 1 < i)
		index_error(__FILE__, __LINE__);

	return value((*THIS)[i]);
}
RUCY_END

static
RUCY_DEF1(op_and, bounds)
{
	CHECK;

	Rays::Bounds b = *THIS;
	b &= to<Rays::Bounds&>(bounds);
	return value(b);
}
RUCY_END

static
RUCY_DEF1(op_or, arg)
{
	CHECK;

	Rays::Bounds b = *THIS;
	if (arg.is_kind_of(Rays::bounds_class()))
		b |= to<Rays::Bounds&>(arg);
	else if (arg.is_kind_of(Rays::point_class()))
		b |= to<Rays::Point&>(arg);
	else
		argument_error(__FILE__, __LINE__);

	return value(b);
}
RUCY_END

static
RUCY_DEF0(inspect)
{
	CHECK;

	return value(Xot::stringf("#<Rays::Bounds %s>", THIS->inspect().c_str()));
}
RUCY_END

static
RUCY_DEF0(invalid)
{
	return value(Rays::invalid_bounds());
}
RUCY_END


static Class cBounds;

void
Init_rays_bounds ()
{
	Module mRays = define_module("Rays");

	cBounds = mRays.define_class("Bounds");
	cBounds.define_alloc_func(alloc);
	cBounds.define_private_method("initialize",      initialize);
	cBounds.define_private_method("initialize_copy", initialize_copy);
	cBounds.define_method("intersect?", intersect);
	cBounds.define_method("include?",   include);
	cBounds.define_method("move_to!",   move_to);
	cBounds.define_method("move_by!",   move_by);
	cBounds.define_method("resize_to!", resize_to);
	cBounds.define_method("resize_by!", resize_by);
	cBounds.define_method("inset_by!",  inset_by);
	cBounds.define_method("valid?", is_valid);
	cBounds.define_method("x=",      set_x);
	cBounds.define_method("x",       get_x);
	cBounds.define_method("y=",      set_y);
	cBounds.define_method("y",       get_y);
	cBounds.define_method("z=",      set_z);
	cBounds.define_method("z",       get_z);
	cBounds.define_method("width=",  set_width);
	cBounds.define_method("width",   get_width);
	cBounds.define_method("height=", set_height);
	cBounds.define_method("height",  get_height);
	cBounds.define_method("depth=",  set_depth);
	cBounds.define_method("depth",   get_depth);
	cBounds.define_method("left=",   set_left);
	cBounds.define_method("left",    get_left);
	cBounds.define_method("right=",  set_right);
	cBounds.define_method("right",   get_right);
	cBounds.define_method("top=",    set_top);
	cBounds.define_method("top",     get_top);
	cBounds.define_method("bottom=", set_bottom);
	cBounds.define_method("bottom",  get_bottom);
	cBounds.define_method("back=",   set_back);
	cBounds.define_method("back",    get_back);
	cBounds.define_method("front=",  set_front);
	cBounds.define_method("front",   get_front);
	cBounds.define_method("position=", set_position);
	cBounds.define_method("position",  get_position);
	cBounds.define_method("size=", set_size);
	cBounds.define_method("size",  get_size);
	cBounds.define_method("center=", set_center);
	cBounds.define_method("center",  get_center);
	cBounds.define_method("[]",  get_at);
	cBounds.define_method("[]=", set_at);
	cBounds.define_method("&", op_and);
	cBounds.define_method("|", op_or);
	cBounds.define_method("inspect", inspect);
	cBounds.define_singleton_method("invalid", invalid);
}


namespace Rucy
{


	template <> RAYS_EXPORT Rays::Bounds
	value_to<Rays::Bounds> (int argc, const Value* argv, bool convert)
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
				return Rays::Bounds();
			else if (argv->is_kind_of(Rays::point_class()))
			{
				switch (argc)
				{
					#define V(i) to<Rays::Point&>(argv[i])
					case 1: return Rays::Bounds(V(0));
					case 2: return Rays::Bounds(V(0), V(1));
					#undef V
					default: argument_error(__FILE__, __LINE__);
				}
			}
			else if (argv->is_num())
			{
				switch (argc)
				{
					#define V(i) argv[i].as_f(true)
					case 1: return Rays::Bounds(V(0));
					case 2: return Rays::Bounds(V(0), V(1));
					case 3: return Rays::Bounds(V(0), V(1), V(2));
					case 4: return Rays::Bounds(V(0), V(1), V(2), V(3));
					case 6: return Rays::Bounds(V(0), V(1), V(2), V(3), V(4), V(5));
					#undef V
					default: argument_error(__FILE__, __LINE__);
				}
			}
		}

		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		return value_to<Rays::Bounds&>(*argv, convert);
	}


}// Rucy


namespace Rays
{


	Class
	bounds_class ()
	{
		return cBounds;
	}


}// Rays
