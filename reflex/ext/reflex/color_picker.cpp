#include "reflex/ruby/color_picker.h"


#include <rays/ruby/color.h>
#include "reflex/ruby/window.h"
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::ColorPicker)

#define THIS      to<Reflex::ColorPicker*>(self)

#define CHECK     RUCY_CHECK_OBJ(Reflex::ColorPicker, self)

#define CALL(fun) RUCY_CALL_SUPER(THIS, fun)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return value(new Reflex::RubyColorPicker<Reflex::ColorPicker>, klass);
}
RUCY_END

static
RUCY_DEF1(pick_color, initial)
{
	CHECK;

	if (initial.is_nil())
		THIS->pick_color();
	else
		THIS->pick_color(to<Rays::Color>(initial));
	return self;
}
RUCY_END

static
RUCY_DEF1(set_owner, owner)
{
	CHECK;
	THIS->set_owner(owner.is_nil() ? NULL : to<Reflex::Window*>(owner));
	return owner;
}
RUCY_END

static
RUCY_DEF0(get_owner)
{
	CHECK;
	return value(THIS->owner());
}
RUCY_END

static
RUCY_DEF1(set_alpha, state)
{
	CHECK;
	THIS->set_alpha(to<bool>(state));
	return state;
}
RUCY_END

static
RUCY_DEF0(is_alpha)
{
	CHECK;
	return value(THIS->alpha());
}
RUCY_END

static
RUCY_DEF1(on_color, event)
{
	CHECK;

	CALL(on_color(to<Reflex::ColorEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_close, event)
{
	CHECK;

	CALL(on_close(to<Reflex::Event*>(event)));
}
RUCY_END


static Class cColorPicker;

void
Init_reflex_color_picker ()
{
	Module mReflex = define_module("Reflex");

	cColorPicker = mReflex.define_class("ColorPicker");
	cColorPicker.define_alloc_func(alloc);
	cColorPicker.define_method("pick_color!", pick_color);
	cColorPicker.define_method("owner=", set_owner);
	cColorPicker.define_method("owner",  get_owner);
	cColorPicker.define_method("alpha=", set_alpha);
	cColorPicker.define_method("alpha?",  is_alpha);
	cColorPicker.define_method("on_color", on_color);
	cColorPicker.define_method("on_close", on_close);
}


namespace Reflex
{


	Class
	color_picker_class ()
	{
		return cColorPicker;
	}


}// Reflex
