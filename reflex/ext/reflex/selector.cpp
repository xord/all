#include "reflex/ruby/selector.h"


#include "defs.h"


RUCY_DEFINE_VALUE_OR_ARRAY_FROM_TO(Reflex::Selector)

#define   THIS to<      Reflex::Selector*>(self)
#define C_THIS to<const Reflex::Selector*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::Selector, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::Selector>(klass);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::Selector&>(obj);
	return self;
}
RUCY_END

static
RUCY_DEF1(set_name, name)
{
	CHECK;
	THIS->set_name(name.is_nil() ? NULL : name.c_str());
}
RUCY_END

static
RUCY_DEF0(get_name)
{
	CHECK;
	const char* name = C_THIS->name();
	return name ? value(name) : nil();
}
RUCY_END

static
RUCY_DEF1(add_tag, tag)
{
	CHECK;
	THIS->add_tag(tag.c_str());
}
RUCY_END

static
RUCY_DEF1(remove_tag, tag)
{
	CHECK;
	THIS->remove_tag(tag.c_str());
}
RUCY_END

static
RUCY_DEF0(clear_tags)
{
	CHECK;
	THIS->clear_tags();
}
RUCY_END

static
RUCY_DEF1(has_tag, tag)
{
	CHECK;
	return value(C_THIS->has_tag(tag.c_str()));
}
RUCY_END

static
RUCY_DEF0(each_tag)
{
	CHECK;

	Value ret;
	Reflex::Selector::const_iterator end = C_THIS->end();
	for (Reflex::Selector::const_iterator it = C_THIS->begin(); it != end; ++it)
		ret = rb_yield(value(*it));
	return ret;
}
RUCY_END

static
RUCY_DEF0(is_empty)
{
	CHECK;
	return value(C_THIS->empty());
}
RUCY_END

static
RUCY_DEF1(contains, selector)
{
	CHECK;
	return value(C_THIS->contains(to<Reflex::Selector&>(selector)));
}
RUCY_END

static
RUCY_DEF1(equal, selector)
{
	CHECK;
	return value(*C_THIS == to<const Reflex::Selector&>(selector));
}
RUCY_END


static Class cSelector;

void
Init_reflex_selector ()
{
	Module mReflex = define_module("Reflex");

	cSelector = mReflex.define_class("Selector");
	cSelector.define_alloc_func(alloc);
	cSelector.define_private_method("initialize_copy", initialize_copy);
	cSelector.define_method("name=", set_name);
	cSelector.define_method("name",  get_name);
	cSelector.define_method("add_tag",    add_tag);
	cSelector.define_method("remove_tag", remove_tag);
	cSelector.define_method("clear_tags", clear_tags);
	cSelector.define_method("tag?",       has_tag);
	cSelector.define_method("each_tag",   each_tag);
	cSelector.define_method("empty?",     is_empty);
	cSelector.define_method("contains", contains);
	cSelector.define_method("==", equal);
}


namespace Rucy
{


	template <> Reflex::Selector
	value_to<Reflex::Selector> (int argc, const Value* argv, bool convert)
	{
		if (argc == 1 && argv->is_array())
		{
			argc = argv->size();
			argv = argv->as_array();
		}

		assert(argc > 0 && argv);

		if (convert)
		{
			if (argc == 1 && (argv->is_s() || argv->is_sym()))
				return Reflex::Selector(argv[0].c_str());
		}

		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		return value_to<Reflex::Selector&>(*argv, convert);
	}


}// Rucy


namespace Reflex
{


	Class
	selector_class ()
	{
		return cSelector;
	}


}// Reflex
