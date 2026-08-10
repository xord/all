#include "reflex/ruby/event.h"


#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::TextEvent)

#define THIS  to<Reflex::TextEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::TextEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::TextEvent>(klass);
}
RUCY_END

static
RUCY_DEF4(initialize, action, text, selection_offset, selection_size)
{
	CHECK;

	*THIS = Reflex::TextEvent(
		(Reflex::TextEvent::Action) to<uint>(action),
		text.c_str(),
		to<int>(selection_offset),
		to<int>(selection_size));

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::TextEvent&>(obj).dup();
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
RUCY_DEF0(get_text)
{
	CHECK;
	return value(THIS->text());
}
RUCY_END

static
RUCY_DEF0(get_selection_offset)
{
	CHECK;
	return value(THIS->selection_offset());
}
RUCY_END

static
RUCY_DEF0(get_selection_size)
{
	CHECK;
	return value(THIS->selection_size());
}
RUCY_END


static Class cTextEvent;

void
Init_reflex_text_event ()
{
	Module mReflex = define_module("Reflex");

	cTextEvent = mReflex.define_class("TextEvent", Reflex::event_class());
	cTextEvent.define_alloc_func(alloc);
	cTextEvent.define_private_method("initialize",      initialize);
	cTextEvent.define_private_method("initialize_copy", initialize_copy);
	cTextEvent.define_method("action", get_action);
	cTextEvent.define_method("text",   get_text);
	cTextEvent.define_private_method("selection_offset!", get_selection_offset);
	cTextEvent.define_private_method("selection_size!",   get_selection_size);

	cTextEvent.define_const("ACTION_NONE", Reflex::TextEvent::ACTION_NONE);
	cTextEvent.define_const("PREEDIT",     Reflex::TextEvent::PREEDIT);
	cTextEvent.define_const("COMMIT",      Reflex::TextEvent::COMMIT);
}


namespace Reflex
{


	Class
	text_event_class ()
	{
		return cTextEvent;
	}


}// Reflex
