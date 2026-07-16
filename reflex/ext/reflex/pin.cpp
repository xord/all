#include "reflex/ruby/pin.h"


#include <rays/ruby/point.h>
#include "reflex/ruby/constraint.h"
#include "reflex/ruby/view.h"
#include "defs.h"


RUCY_DEFINE_VALUE_OR_ARRAY_FROM_TO(REFLEX_EXPORT, Reflex::Pin)

#define THIS  to<Reflex::Pin*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::Pin, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::Pin>(klass);
}
RUCY_END

static
RUCY_DEFN(initialize)
{
	CHECK;
	*THIS = to<Reflex::Pin>(argc, argv);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::Pin&>(obj);
}
RUCY_END

static
RUCY_DEFN(snap)
{
	CHECK;
	return value(THIS->snap(to<Reflex::Pin>(argc, argv)));
}
RUCY_END

static
RUCY_DEFN(link)
{
	CHECK;
	return value(THIS->link(to<Reflex::Pin>(argc, argv)));
}
RUCY_END

static
RUCY_DEFN(wheel)
{
	CHECK;
	return value(THIS->wheel(to<Reflex::Pin>(argc, argv)));
}
RUCY_END

static
RUCY_DEFN(chase)
{
	CHECK;
	return value(THIS->chase(to<Reflex::Pin>(argc, argv)));
}
RUCY_END

static
RUCY_DEF0(get_view)
{
	CHECK;
	return value(THIS->view());
}
RUCY_END

static
RUCY_DEF0(get_position)
{
	CHECK;
	const Rays::Point* pos = THIS->position();
	return pos ? value(*pos) : nil();
}
RUCY_END


static Class cPin;

void
Init_reflex_pin ()
{
	Module mReflex = define_module("Reflex");

	cPin = mReflex.define_class("Pin");
	cPin.define_alloc_func(alloc);
	cPin.define_private_method("initialize",      initialize);
	cPin.define_private_method("initialize_copy", initialize_copy);
	cPin.define_private_method("snap!",  snap);
	cPin.define_private_method("link!",  link);
	cPin.define_private_method("wheel!", wheel);
	cPin.define_private_method("chase!", chase);
	cPin.define_method("view",     get_view);
	cPin.define_method("position", get_position);
}


namespace Rucy
{


	template <> REFLEX_EXPORT Reflex::Pin
	value_to<Reflex::Pin> (int argc, const Value* argv, bool convert)
	{
		if (argc == 1 && argv->is_array())
		{
			argc = argv->size();
			argv = argv->as_array();
		}

		assert(argc == 0 || (argc > 0 && argv));

		if (convert)
		{
			if (argc == 0 || argv->is_nil())
				return Reflex::Pin();

			if (argv->is_a(Reflex::view_class()))
			{
				Reflex::View* view = value_to<Reflex::View*>(*argv);
				argc -= 1;
				argv += 1;

				if (argc == 0)
					return Reflex::Pin(view);
				else
					return Reflex::Pin(view, value_to<Rays::Point>(argc, argv, convert));
			}

			if (!argv->is_a(Reflex::pin_class()))
				return Reflex::Pin(value_to<Rays::Point>(argc, argv, convert));
		}

		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		return value_to<Reflex::Pin&>(*argv, convert);
	}


}// Rucy


namespace Reflex
{


	Class
	pin_class ()
	{
		return cPin;
	}


}// Reflex
