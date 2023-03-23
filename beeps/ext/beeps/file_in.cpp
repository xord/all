#include "beeps/ruby/processor.h"


#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(Beeps::FileIn)

#define THIS  to<Beeps::FileIn*>(self)

#define CHECK RUCY_CHECK_OBJECT(Beeps::FileIn, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Beeps::FileIn>(klass);
}
RUCY_END

static
RUCY_DEF1(initialize, path)
{
	RUCY_CHECK_OBJ(Beeps::FileIn, self);

	*THIS = Beeps::FileIn(to<const char*>(path));
	return self;
}
RUCY_END

static
RUCY_DEF0(sampling_rate)
{
	CHECK;

	return value(THIS->sampling_rate());
}
RUCY_END

static
RUCY_DEF0(nchannels)
{
	CHECK;

	return value(THIS->nchannels());
}
RUCY_END

static
RUCY_DEF0(seconds)
{
	CHECK;

	return value(THIS->seconds());
}
RUCY_END


static Class cFileIn;

void
Init_beeps_file_in ()
{
	Module mBeeps = define_module("Beeps");

	cFileIn = mBeeps.define_class("FileIn", Beeps::processor_class());
	cFileIn.define_alloc_func(alloc);
	cFileIn.define_private_method("initialize", initialize);
	cFileIn.define_method("sampling_rate", sampling_rate);
	cFileIn.define_method("nchannels",     nchannels);
	cFileIn.define_method("seconds",       seconds);
}


namespace Beeps
{


	Class
	file_in_class ()
	{
		return cFileIn;
	}


}// Beeps
