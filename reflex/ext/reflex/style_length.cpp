#include "reflex/ruby/style.h"


#include <assert.h>
#include "defs.h"


RUCY_DEFINE_VALUE_OR_ARRAY_FROM_TO(Reflex::StyleLength)

#define THIS  to<Reflex::StyleLength*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::StyleLength, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::StyleLength>(klass);
}
RUCY_END

static Reflex::StyleLength::Type
str2type (const char* s)
{
	     if (strcasecmp(s, "px")   == 0) return Reflex::StyleLength::PIXEL;
	else if (strcasecmp(s, "%")    == 0) return Reflex::StyleLength::PERCENT;
	else if (strcasecmp(s, "fill") == 0) return Reflex::StyleLength::FILL;
	else if (strcasecmp(s, "fit")  == 0) return Reflex::StyleLength::FIT;
	else                                 return Reflex::StyleLength::NONE;
}

static const char*
type2str (Reflex::StyleLength::Type type)
{
	switch (type)
	{
		case Reflex::StyleLength::PIXEL:   return "px";
		case Reflex::StyleLength::PERCENT: return "%";
		case Reflex::StyleLength::FILL:    return "fill";
		case Reflex::StyleLength::FIT:     return "fit";
		default:                           return NULL;
	}
}

static bool
get_default_value (
	Reflex::StyleLength::Value* value, Reflex::StyleLength::Type type)
{
	assert(value);

	switch (type)
	{
		case Reflex::StyleLength::FILL:
			*value = 1;
			break;

		case Reflex::StyleLength::FIT:
			*value = 1;
			break;

		default:
			return false;
	}

	return true;
}

static bool
scan_type_and_value (
	Reflex::StyleLength::Type* type, Reflex::StyleLength::Value* value,
	const char* str)
{
	assert(type && value);

	if (!str || *str == '\0')
		argument_error(__FILE__, __LINE__);

	char buf[101];

	if (sscanf(str, "%100s%f", buf, value) == 2)
		argument_error(__FILE__, __LINE__);

	int count = sscanf(str, "%f%100s", value, buf);
	if (count == 2)
	{
		*type = str2type(buf);
		return true;
	}

	count = sscanf(str, "%100s", buf);
	if (count == 1)
	{
		*type = str2type(buf);
		return get_default_value(value, *type);
	}

	return false;
}

static
RUCY_DEFN(initialize)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "StyleLength#initialize", argc, 0, 1);

	if (argc == 0 || argv[0].is_nil())
		THIS->reset();
	else if (argv[0].is_i())
		THIS->reset(Reflex::StyleLength::PIXEL, argv[0].as_i());
	else if (argv[0].is_f())
		THIS->reset(Reflex::StyleLength::PIXEL, argv[0].as_f());
	else if (argv[0].is_s() || argv[0].is_sym())
	{
		Reflex::StyleLength::Type type   = Reflex::StyleLength::NONE;
		Reflex::StyleLength::Value value = 0;
		if (!scan_type_and_value(&type, &value, argv[0].c_str()))
			argument_error(__FILE__, __LINE__);

		THIS->reset(type, value);
	}
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::StyleLength&>(obj).copy();
	return self;
}
RUCY_END

static
RUCY_DEF0(get_type)
{
	CHECK;

	RUCY_SYMBOL(pixel,   "px");
	RUCY_SYMBOL(percent, "%");
	RUCY_SYMBOL(fill,    "fill");
	RUCY_SYMBOL(fit,     "fit");
	switch (THIS->type())
	{
		case Reflex::StyleLength::PIXEL:   return pixel.value();
		case Reflex::StyleLength::PERCENT: return percent.value();
		case Reflex::StyleLength::FILL:    return fill.value();
		case Reflex::StyleLength::FIT:     return fit.value();
		default:                           return nil();
	}
}
RUCY_END

static
RUCY_DEF0(get_value)
{
	CHECK;
	return value(THIS->value());
}
RUCY_END

static bool
has_default_value (const Reflex::StyleLength& length)
{
	Reflex::StyleLength::Value defval;
	if (!get_default_value(&defval, length.type()))
		return false;

	return length.value() == defval;
}

static
RUCY_DEF0(to_s)
{
	CHECK;

	if (!*THIS)
		return value("");

	Reflex::String val;
	if (has_default_value(*THIS))
		val = "";
	else if (fmod(THIS->value(), 1) == 0)
		val = Xot::stringf("%d", (long) THIS->value());
	else
		val = Xot::stringf("%g", THIS->value());

	const char* type = type2str(THIS->type());
	if (!type)
		invalid_state_error(__FILE__, __LINE__);

	return value(val + type);
}
RUCY_END


static Class cStyleLength;

void
Init_reflex_style_length ()
{
	Module mReflex = define_module("Reflex");

	cStyleLength = mReflex.define_class("StyleLength");
	cStyleLength.define_alloc_func(alloc);
	cStyleLength.define_private_method("initialize",      initialize);
	cStyleLength.define_private_method("initialize_copy", initialize_copy);
	cStyleLength.define_method("type",   get_type);
	cStyleLength.define_method("value",  get_value);
	cStyleLength.define_method("to_s", to_s);
}


namespace Rucy
{


	template <> Reflex::StyleLength
	value_to<Reflex::StyleLength> (int argc, const Value* argv, bool convert)
	{
		if (argc == 1 && argv->is_array())
		{
			argc = argv->size();
			argv = argv->as_array();
		}

		assert(argc > 0 && argv);

		if (convert)
		{
			if (argv->is_nil())
				return Reflex::StyleLength();
			else if (argv->is_i())
				return Reflex::StyleLength(Reflex::StyleLength::PIXEL, argv[0].as_i());
			else if (argv->is_f())
				return Reflex::StyleLength(Reflex::StyleLength::PIXEL, argv[0].as_f());
			else if (argv->is_s() || argv->is_sym())
			{
				Reflex::StyleLength::Type type   = Reflex::StyleLength::NONE;
				Reflex::StyleLength::Value value = 0;
				if (!scan_type_and_value(&type, &value, argv[0].c_str()))
					argument_error(__FILE__, __LINE__);

				return Reflex::StyleLength(type, value);
			}
		}

		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		return value_to<Reflex::StyleLength&>(*argv, convert);
	}


}// Rucy


namespace Reflex
{


	Class
	style_length_class ()
	{
		return cStyleLength;
	}


}// Reflex
