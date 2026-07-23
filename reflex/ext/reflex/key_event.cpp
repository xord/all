#include "reflex/ruby/event.h"


#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::KeyEvent)

#define THIS  to<Reflex::KeyEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::KeyEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::KeyEvent>(klass);
}
RUCY_END

static
RUCY_DEF5(initialize, action, chars, code, modifiers, repeat)
{
	CHECK;

	*THIS = Reflex::KeyEvent(
		(Reflex::KeyEvent::Action) to<uint>(action),
		chars.c_str(),
		to<int>(code),
		to<uint>(modifiers),
		to<int>(repeat));

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::KeyEvent&>(obj).dup();
	return self;
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
RUCY_DEF0(get_chars)
{
	CHECK;
	const char* chars = THIS->chars();
	return chars ? value(chars) : nil();
}
RUCY_END

static
RUCY_DEF0(get_code)
{
	CHECK;
	return value(THIS->code());
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
RUCY_DEF0(get_repeat)
{
	CHECK;
	return value(THIS->repeat());
}
RUCY_END

static
RUCY_DEF0(is_captured)
{
	CHECK;
	return value(THIS->is_captured());
}
RUCY_END


static Class cKeyEvent;

void
Init_reflex_key_event ()
{
	Module mReflex = define_module("Reflex");

	cKeyEvent = mReflex.define_class("KeyEvent", Reflex::event_class());
	cKeyEvent.define_alloc_func(alloc);
	cKeyEvent.define_private_method("initialize",      initialize);
	cKeyEvent.define_private_method("initialize_copy", initialize_copy);
	cKeyEvent.define_method("action",    get_action);
	cKeyEvent.define_method("chars",     get_chars);
	cKeyEvent.define_method("code",      get_code);
	cKeyEvent.define_method("modifiers", get_modifiers);
	cKeyEvent.define_method("repeat",    get_repeat);
	cKeyEvent.define_method("captured?", is_captured);

	cKeyEvent.define_const("ACTION_NONE", Reflex::KeyEvent::ACTION_NONE);
	cKeyEvent.define_const("DOWN",        Reflex::KeyEvent::DOWN);
	cKeyEvent.define_const("UP",          Reflex::KeyEvent::UP);
}


namespace Reflex
{


	Class
	key_event_class ()
	{
		return cKeyEvent;
	}


}// Reflex
