#include "reflex/ruby/pointer.h"


#include <rays/ruby/point.h>
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(Reflex::Pointer)

#define THIS  to<Reflex::Pointer*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::Pointer, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::Pointer>(klass);
}
RUCY_END

static
RUCY_DEF9(initialize,
	id, types, action, position, modifiers, drag, click_count, view_index, time)
{
	CHECK;

	*THIS = Reflex::Pointer(
		to<Reflex::Pointer::ID>(id),
		to<uint>(types),
		(Reflex::Pointer::Action) to<int>(action),
		to<Rays::Point>(position),
		to<uint>(modifiers),
		to<bool>(drag),
		to<uint>(click_count),
		to<uint>(view_index),
		to<double>(time));
	return self;
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::Pointer&>(obj);
	return self;
}
RUCY_END

static
RUCY_DEF0(get_id)
{
	CHECK;
	return value(THIS->id());
}
RUCY_END

static
RUCY_DEF0(get_types)
{
	CHECK;
	return value(THIS->types());
}
RUCY_END

static
RUCY_DEF0(get_action)
{
	CHECK;
	return value(THIS->action());
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
RUCY_DEF0(get_modifiers)
{
	CHECK;
	return value(THIS->modifiers());
}
RUCY_END

static
RUCY_DEF0(is_drag)
{
	CHECK;
	return value(THIS->is_drag());
}
RUCY_END

static
RUCY_DEF0(get_click_count)
{
	CHECK;
	return value(THIS->click_count());
}
RUCY_END

static
RUCY_DEF0(get_view_index)
{
	CHECK;
	return value(THIS->view_index());
}
RUCY_END

static
RUCY_DEF0(get_time)
{
	CHECK;
	return value(THIS->time());
}
RUCY_END

static
RUCY_DEF0(get_prev)
{
	CHECK;
	return value(THIS->prev());
}
RUCY_END

static
RUCY_DEF0(get_down)
{
	CHECK;
	return value(THIS->down());
}
RUCY_END


static Class cPointer;

void
Init_reflex_pointer ()
{
	Module mReflex = define_module("Reflex");

	cPointer = mReflex.define_class("Pointer");
	cPointer.define_alloc_func(alloc);
	cPointer.define_private_method("initialize",      initialize);
	cPointer.define_private_method("initialize_copy", initialize_copy);
	cPointer.define_method("id",                 get_id);
	cPointer.define_private_method("get_types",  get_types);
	cPointer.define_private_method("get_action", get_action);
	cPointer.define_method("position",           get_position);
	cPointer.define_method("modifiers",          get_modifiers);
	cPointer.define_method("drag?",              is_drag);
	cPointer.define_method("click_count",        get_click_count);
	cPointer.define_method("view_index",         get_view_index);
	cPointer.define_method("time",               get_time);
	cPointer.define_method("prev",               get_prev);
	cPointer.define_method("down",               get_down);
	cPointer.define_const("TYPE_NONE",    Reflex::Pointer::TYPE_NONE);
	cPointer.define_const("MOUSE",        Reflex::Pointer::MOUSE);
	cPointer.define_const("MOUSE_LEFT",   Reflex::Pointer::MOUSE_LEFT);
	cPointer.define_const("MOUSE_RIGHT",  Reflex::Pointer::MOUSE_RIGHT);
	cPointer.define_const("MOUSE_MIDDLE", Reflex::Pointer::MOUSE_MIDDLE);
	cPointer.define_const("TOUCH",        Reflex::Pointer::TOUCH);
	cPointer.define_const("PEN",          Reflex::Pointer::PEN);
	cPointer.define_const("ACTION_NONE", Reflex::Pointer::ACTION_NONE);
	cPointer.define_const("DOWN",        Reflex::Pointer::DOWN);
	cPointer.define_const("UP",          Reflex::Pointer::UP);
	cPointer.define_const("MOVE",        Reflex::Pointer::MOVE);
	cPointer.define_const("CANCEL",      Reflex::Pointer::CANCEL);
	cPointer.define_const("STAY",        Reflex::Pointer::STAY);
}


namespace Reflex
{


	Class
	pointer_class ()
	{
		return cPointer;
	}


}// Reflex
