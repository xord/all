#include "rays/ruby/matrix.h"


#include "rays/ruby/point.h"
#include "defs.h"


RUCY_DEFINE_VALUE_OR_ARRAY_FROM_TO(Rays::Matrix)

#define THIS  to<Rays::Matrix*>(self)

#define CHECK RUCY_CHECK_OBJ(Rays::Matrix, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::Matrix>(klass);
}
RUCY_END

static
RUCY_DEFN(initialize)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Matrix#initialize", argc, 0, 1, 16);

	if (argc > 0)
		*THIS = to<Rays::Matrix>(argc, argv);

	return self;
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Rays::Matrix&>(obj);
	return self;
}
RUCY_END

static
RUCY_DEFN(reset)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Matrix#reset", argc, 0, 1, 16);

	switch (argc)
	{
		case 0:
			THIS->reset();
			break;

		case 1:
			THIS->reset(to<float>(argv[0]));
			break;

		case 16:
			THIS->reset(
				to<float>(argv[0]),  to<float>(argv[1]),  to<float>(argv[2]),  to<float>(argv[3]),
				to<float>(argv[4]),  to<float>(argv[5]),  to<float>(argv[6]),  to<float>(argv[7]),
				to<float>(argv[8]),  to<float>(argv[9]),  to<float>(argv[10]), to<float>(argv[11]),
				to<float>(argv[12]), to<float>(argv[13]), to<float>(argv[14]), to<float>(argv[15]));
			break;
	}

	return self;
}
RUCY_END

static
RUCY_DEFN(translate)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Matrix#translate", argc, 1, 2, 3);

	THIS->translate(to<Rays::Point>(argc, argv));
	return self;
}
RUCY_END

static
RUCY_DEFN(scale)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Matrix#scale", argc, 1, 2, 3);

	THIS->scale(to<Rays::Point>(argc, argv));
	return self;
}
RUCY_END

static
RUCY_DEFN(rotate)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Matrix#rotate", argc, 1, 2, 4);

	float degree = to<float>(argv[0]);

	if (argc == 1)
		THIS->rotate(degree);
	else
		THIS->rotate(degree, to<Rays::Point>(argc - 1, argv + 1));

	return self;
}
RUCY_END

static
RUCY_DEF0(to_a)
{
	CHECK;
	return array(
		THIS->x0, THIS->y0, THIS->z0, THIS->w0,
		THIS->x1, THIS->y1, THIS->z1, THIS->w1,
		THIS->x2, THIS->y2, THIS->z2, THIS->w2,
		THIS->x3, THIS->y3, THIS->z3, THIS->w3);
}
RUCY_END

static
RUCY_DEF1(mult, val)
{
	CHECK;

	if (val.is_kind_of(Rays::matrix_class()))
		return value(*THIS * to<Rays::Matrix&>(val));

	if (val.is_kind_of(Rays::point_class()))
		return value(*THIS * to<Rays::Point&>(val));

	if (val.is_array())
	{
		if (val.size() == 16)
			return value(*THIS * to<Rays::Matrix>(val));
		else
			return value(*THIS * to<Rays::Point>(val));
	}

	argument_error(__FILE__, __LINE__);
}
RUCY_END

static
RUCY_DEF3(set_at, row, column, val)
{
	CHECK;
	return value(THIS->at(row.as_i(), column.as_i()) = to<float>(val));
}
RUCY_END

static
RUCY_DEF2(get_at, row, column)
{
	CHECK;
	return value(THIS->at(row.as_i(), column.as_i()));
}
RUCY_END

static
RUCY_DEF1(compare, other)
{
	CHECK;

	const Rays::Matrix& a = *THIS;
	const Rays::Matrix& b = to<const Rays::Matrix&>(other);
	for (int i = 0; i < Rays::Matrix::NELEM; ++i)
	{
		if (a[i] == b[i]) continue;
		return value(a[i] < b[i] ? -1 : +1);
	}
	return value(0);
}
RUCY_END

static
RUCY_DEF0(inspect)
{
	CHECK;
	return value(Xot::stringf("#<Rays::Matrix %s>", THIS->inspect().c_str()));
}
RUCY_END

static
RUCY_DEFN(s_translate)
{
	return translate(argc, argv, value(Rays::Matrix()));
}
RUCY_END

static
RUCY_DEFN(s_scale)
{
	return scale(argc, argv, value(Rays::Matrix()));
}
RUCY_END

static
RUCY_DEFN(s_rotate)
{
	return rotate(argc, argv, value(Rays::Matrix()));
}
RUCY_END


static Class cMatrix;

void
Init_rays_matrix ()
{
	Module mRays = define_module("Rays");

	cMatrix = mRays.define_class("Matrix");
	cMatrix.define_alloc_func(alloc);
	cMatrix.define_private_method("initialize",      initialize);
	cMatrix.define_private_method("initialize_copy", initialize_copy);
	cMatrix.define_method("reset", reset);
	cMatrix.define_method("translate", translate);
	cMatrix.define_method("scale",     scale);
	cMatrix.define_method("rotate",    rotate);
	cMatrix.define_method("to_a", to_a);
	cMatrix.define_method("*", mult);
	cMatrix.define_method("[]=", set_at);
	cMatrix.define_method("[]",  get_at);
	cMatrix.define_method("<=>", compare);
	cMatrix.define_method("inspect", inspect);

	cMatrix.define_singleton_method("translate", s_translate);
	cMatrix.define_singleton_method("scale",     s_scale);
	cMatrix.define_singleton_method("rotate",    s_rotate);
}


namespace Rucy
{


	template <> Rays::Matrix
	value_to<Rays::Matrix> (int argc, const Value* argv, bool convert)
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
				return Rays::Matrix();
			else if (argv->is_num())
			{
				switch (argc)
				{
					#define V(i) argv[i].as_f(true)
					case 1:  return Rays::Matrix(V(0));
					case 16: return Rays::Matrix(
						V(0),  V(1),  V(2),  V(3),
						V(4),  V(5),  V(6),  V(7),
						V(8),  V(9),  V(10), V(11),
						V(12), V(13), V(14), V(15));
					#undef V
					default: argument_error(__FILE__, __LINE__);
				}
			}
		}

		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		return value_to<Rays::Matrix&>(*argv, convert);
	}


}// Rucy


namespace Rays
{


	Class
	matrix_class ()
	{
		return cMatrix;
	}


}// Rays
