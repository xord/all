#include "beeps/ruby/processor.h"


#include "beeps/exception.h"
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(BEEPS_EXPORT, Beeps::Processor)

#define THIS  to<Beeps::Processor*>(self)

#define CHECK RUCY_CHECK_OBJ(Beeps::Processor, self)

#define CALL(fun) RUCY_CALL_SUPER(THIS, fun)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	Beeps::beeps_error(__FILE__, __LINE__);
}
RUCY_END

static
RUCY_DEF0(reset)
{
	CHECK;

	THIS->reset();
	return self;
}
RUCY_END

static
RUCY_DEF1(set_input, input)
{
	CHECK;

	THIS->set_input(input ? to<Beeps::Processor*>(input) : NULL);
	return input;
}
RUCY_END

static
RUCY_DEF0(get_input)
{
	CHECK;

	return value(THIS->input());
}
RUCY_END

static
RUCY_DEF0(on_start)
{
	CHECK;
	CALL(on_start());
}
RUCY_END


static Class cProcessor;

void
Init_beeps_processor ()
{
	Module mBeeps = define_module("Beeps");

	cProcessor = mBeeps.define_class("Processor");
	cProcessor.define_alloc_func(alloc);
	cProcessor.define_method("reset", reset);
	cProcessor.define_method("input=", set_input);
	cProcessor.define_method("input",  get_input);
	cProcessor.define_method("on_start", on_start);
}


namespace Beeps
{


	Class
	processor_class ()
	{
		return cProcessor;
	}


}// Beeps
