#include "reflex/ruby/ai.h"


#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::AI)

#define THIS  to<Reflex::AI*>(self)

#define CHECK RUCY_CHECK_OBJECT(Reflex::AI, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::AI>(klass);
}
RUCY_END

static
RUCY_DEFN(initialize)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "AI#initialize", argc, 0, 1);

	if (argc == 1)
		*THIS = Reflex::AI(argv[0].c_str());

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(generate, prompt)
{
	CHECK;
	return value(THIS->generate(prompt.c_str()), rb_utf8_encoding());
}
RUCY_END


static Class cAI;

void
Init_reflex_ai ()
{
	Module mReflex = define_module("Reflex");

	cAI = mReflex.define_class("AI");
	cAI.define_alloc_func(alloc);
	cAI.define_private_method("initialize", initialize);
	cAI.define_method("generate", generate);
}


namespace Reflex
{


	Class
	ai_class ()
	{
		return cAI;
	}


}// Reflex
