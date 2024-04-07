#include "reflex/ruby/image_view.h"


#include <rays/ruby/point.h>
#include "reflex/ruby/view.h"
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::ImageView)

#define THIS      to<Reflex::ImageView*>(self)

#define CHECK     RUCY_CHECK_OBJECT(Reflex::ImageView, self)

#define CALL(fun) RUCY_WRAPPER_CALL(Reflex::ImageView, THIS, fun)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return value(new Reflex::RubyView<Reflex::ImageView>, klass);
}
RUCY_END

static
RUCY_DEF0(get_image)
{
	CHECK;
	Rays::Image image = THIS->get_image();
	return image ? value(image) : nil();
}
RUCY_END

static
RUCY_DEF1(set_image, image)
{
	CHECK;
	THIS->set_image(image ? to<Rays::Image&>(image) : Rays::Image());
	return image;
}
RUCY_END


static Class cImageView;

void
Init_reflex_image_view ()
{
	Module mReflex = define_module("Reflex");

	cImageView = mReflex.define_class("ImageView", Reflex::view_class());
	cImageView.define_alloc_func(alloc);
	cImageView.define_private_method("set_image", set_image);
	cImageView.define_method(            "image", get_image);
}


namespace Reflex
{


	Class
	image_view_class ()
	{
		return cImageView;
	}


}// Reflex
