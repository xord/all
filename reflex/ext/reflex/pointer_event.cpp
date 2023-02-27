#include "reflex/ruby/event.h"


#include <vector>
#include <rays/ruby/point.h>
#include "reflex/ruby/pointer.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(Reflex::PointerEvent)

#define THIS  to<Reflex::PointerEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::PointerEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::PointerEvent>(klass);
}
RUCY_END

static
RUCY_DEFN(initialize)
{
	CHECK;

	if (argc == 0)
		argument_error(__FILE__, __LINE__);

	std::vector<Reflex::Pointer> pointers;
	for (size_t i = 0; i < argc; ++i)
		pointers.emplace_back(to<Reflex::Pointer&>(argv[i]));

	*THIS = Reflex::PointerEvent(&pointers[0], pointers.size());

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::PointerEvent&>(obj).dup();
	return self;
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
RUCY_DEF0(is_empty)
{
	CHECK;
	return value(THIS->empty());
}
RUCY_END

static
RUCY_DEF0(is_captured)
{
	CHECK;
	return value(THIS->is_captured());
}
RUCY_END

static
RUCY_DEF1(get_at, index)
{
	CHECK;

	int size = (int) THIS->size();
	int i    = to<int>(index);
	if (i < -size || size <= i)
		return Qnil;

	return value((*THIS)[i >= 0 ? i : i + size]);
}
RUCY_END

static
RUCY_DEF0(each)
{
	CHECK;

	Value ret;
	for (size_t i = 0, size = THIS->size(); i < size; ++i)
		ret = rb_yield(value((*THIS)[i]));
	return ret;
}
RUCY_END


static Class cPointerEvent;

void
Init_reflex_pointer_event ()
{
	Module mReflex = define_module("Reflex");

	cPointerEvent = mReflex.define_class("PointerEvent", Reflex::event_class());
	cPointerEvent.define_alloc_func(alloc);
	cPointerEvent.define_private_method("initialize",      initialize);
	cPointerEvent.define_private_method("initialize_copy", initialize_copy);
	cPointerEvent.define_method("size",      get_size);
	cPointerEvent.define_method("empty?",    is_empty);
	cPointerEvent.define_method("captured?", is_captured);
	cPointerEvent.define_method("[]",        get_at);
	cPointerEvent.define_method("each",      each);
}


namespace Reflex
{


	Class
	pointer_event_class ()
	{
		return cPointerEvent;
	}


}// Reflex
