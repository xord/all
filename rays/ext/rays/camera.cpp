#include "rays/ruby/camera.h"


#include "rays/ruby/image.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(Rays::Camera)

#define THIS  to<Rays::Camera*>(self)

#define CHECK RUCY_CHECK_OBJECT(Rays::Camera, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::Camera>(klass);
}
RUCY_END

static
RUCY_DEF5(setup, device_name, min_width, min_height, resize, crop)
{
	RUCY_CHECK_OBJ(Rays::Camera, self);

	*THIS = Rays::Camera(
		device_name ? device_name.c_str() : NULL,
		to<int>(min_width), to<int>(min_height),
		to<bool>(resize), to<bool>(crop));
	return self;
}
RUCY_END

static
RUCY_DEF0(start)
{
	CHECK;
	return value(THIS->start());
}
RUCY_END

static
RUCY_DEF0(stop)
{
	CHECK;
	THIS->stop();
}
RUCY_END

static
RUCY_DEF0(is_active)
{
	CHECK;
	return value(THIS->is_active());
}
RUCY_END

static
RUCY_DEF1(set_min_width, width)
{
	CHECK;
	THIS->set_min_width(to<int>(width));
	return value(THIS->min_width());
}
RUCY_END

static
RUCY_DEF0(min_width)
{
	CHECK;
	return value(THIS->min_width());
}
RUCY_END

static
RUCY_DEF1(set_min_height, height)
{
	CHECK;
	THIS->set_min_height(to<int>(height));
	return value(THIS->min_height());
}
RUCY_END

static
RUCY_DEF0(min_height)
{
	CHECK;
	return value(THIS->min_height());
}
RUCY_END

static
RUCY_DEF1(set_resize, resize)
{
	CHECK;
	THIS->set_resize(to<bool>(resize));
	return value(THIS->is_resize());
}
RUCY_END

static
RUCY_DEF0(is_resize)
{
	CHECK;
	return value(THIS->is_resize());
}
RUCY_END

static
RUCY_DEF1(set_crop, crop)
{
	CHECK;
	THIS->set_crop(to<bool>(crop));
	return value(THIS->is_crop());
}
RUCY_END

static
RUCY_DEF0(is_crop)
{
	CHECK;
	return value(THIS->is_crop());
}
RUCY_END

static
RUCY_DEF0(image)
{
	CHECK;
	const Rays::Image* img = THIS->image();
	return img ? value(*img) : nil();
}
RUCY_END

static
RUCY_DEF0(device_names)
{
	auto names = Rays::get_camera_device_names();

	std::vector<Value> v;
	for (auto it = names.begin(), end = names.end(); it != end; ++it)
		v.emplace_back(value(it->c_str()));
	return value(v.size(), &v[0]);
}
RUCY_END


static Class cCamera;

void
Init_rays_camera ()
{
	Module mRays = define_module("Rays");

	cCamera = mRays.define_class("Camera");
	cCamera.define_alloc_func(alloc);
	cCamera.define_private_method("setup", setup);
	cCamera.define_method("start", start);
	cCamera.define_method("stop",  stop);
	cCamera.define_method("active?", is_active);
	cCamera.define_method("min_width=",  set_min_width);
	cCamera.define_method("min_width",       min_width);
	cCamera.define_method("min_height=", set_min_height);
	cCamera.define_method("min_height",      min_height);
	cCamera.define_method("resize=", set_resize);
	cCamera.define_method("resize?",  is_resize);
	cCamera.define_method("crop=",   set_crop);
	cCamera.define_method("crop?",    is_crop);
	cCamera.define_method("image", image);
	cCamera.define_module_function("device_names", device_names);
}


namespace Rays
{


	Class
	camera_class ()
	{
		return cCamera;
	}


}// Rays
