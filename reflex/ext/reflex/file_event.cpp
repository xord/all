#include "reflex/ruby/event.h"


#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::FileEvent)

#define THIS  to<Reflex::FileEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::FileEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::FileEvent>(klass);
}
RUCY_END

static
RUCY_DEF2(initialize, action, paths)
{
	CHECK;

	if (!paths.is_array())
		argument_error(__FILE__, __LINE__);

	Reflex::StringList list;
	int size = paths.size();
	for (int i = 0; i < size; ++i)
	{
		if (paths[i].is_nil())
			argument_error(__FILE__, __LINE__);

		list.emplace_back(paths[i].c_str());
	}
	*THIS = Reflex::FileEvent((Reflex::FileEvent::Action) to<uint>(action), list);

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::FileEvent&>(obj).dup();
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
RUCY_DEF0(get_paths)
{
	CHECK;

	const Reflex::StringList& paths = THIS->paths();

	std::vector<Value> values;
	for (const auto& path : paths)
		values.emplace_back(path.c_str());

	return array(values.data(), values.size());
}
RUCY_END


static Class cFileEvent;

void
Init_reflex_file_event ()
{
	Module mReflex = define_module("Reflex");

	cFileEvent = mReflex.define_class("FileEvent", Reflex::event_class());
	cFileEvent.define_alloc_func(alloc);
	cFileEvent.define_private_method("initialize",      initialize);
	cFileEvent.define_private_method("initialize_copy", initialize_copy);
	cFileEvent.define_method("action", get_action);
	cFileEvent.define_method("paths",  get_paths);

	cFileEvent.define_const("ACTION_NONE", Reflex::FileEvent::ACTION_NONE);
	cFileEvent.define_const("OPEN",        Reflex::FileEvent::OPEN);
	cFileEvent.define_const("SAVE",        Reflex::FileEvent::SAVE);
}


namespace Reflex
{


	Class
	file_event_class ()
	{
		return cFileEvent;
	}


}// Reflex
